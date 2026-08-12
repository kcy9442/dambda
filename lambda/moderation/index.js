const { BedrockRuntimeClient, ApplyGuardrailCommand } = require('@aws-sdk/client-bedrock-runtime');
const { ComprehendClient, DetectToxicContentCommand } = require('@aws-sdk/client-comprehend');
const { RekognitionClient, DetectModerationLabelsCommand } = require('@aws-sdk/client-rekognition');
const { DynamoDBClient, UpdateItemCommand } = require('@aws-sdk/client-dynamodb');
const { S3Client, DeleteObjectCommand } = require('@aws-sdk/client-s3');
const { TranslateClient, TranslateTextCommand } = require('@aws-sdk/client-translate');

const region = process.env.AWS_REGION;
const guardrailId = process.env.BEDROCK_GUARDRAIL_ID;
const guardrailVersion = process.env.BEDROCK_GUARDRAIL_VERSION;
const bedrock = new BedrockRuntimeClient({ region });
const comprehend = new ComprehendClient({ region });
const rekognition = new RekognitionClient({ region });
const dynamodb = new DynamoDBClient({ region });
const s3 = new S3Client({ region });
const translate = new TranslateClient({ region });
const reviewsTableName = process.env.PRODUCT_REVIEWS_TABLE_NAME;
const MIN_MODERATION_CONFIDENCE = 70;
const COMPREHEND_TOXICITY_THRESHOLD = Number(process.env.COMPREHEND_TOXICITY_THRESHOLD || '0.80');

async function checkText(text) {
  if (!text || !text.trim()) return { approved: true, reasons: [] };
  if (!guardrailId || !guardrailVersion) {
    throw new Error('BEDROCK_GUARDRAIL_ID and BEDROCK_GUARDRAIL_VERSION are required');
  }

  const result = await bedrock.send(new ApplyGuardrailCommand({
    guardrailIdentifier: guardrailId,
    guardrailVersion,
    source: 'INPUT',
    content: [{ text: { text: text.trim() } }],
  }));

  const reasons = new Set();
  for (const assessment of result.assessments || []) {
    for (const filter of assessment.contentPolicy?.filters || []) {
      if (filter.action === 'BLOCKED') reasons.add(`text:${filter.type || 'CONTENT_POLICY'}`);
    }
    for (const topic of assessment.topicPolicy?.topics || []) {
      if (topic.action === 'BLOCKED') reasons.add(`text:TOPIC:${topic.name || 'DENIED'}`);
    }
    for (const word of assessment.wordPolicy?.customWords || []) {
      if (word.action === 'BLOCKED') reasons.add('text:CUSTOM_WORD');
    }
    for (const entity of assessment.sensitiveInformationPolicy?.piiEntities || []) {
      if (entity.action === 'BLOCKED') reasons.add(`text:PII:${entity.type || 'UNKNOWN'}`);
    }
  }

  const intervened = result.action === 'GUARDRAIL_INTERVENED';
  if (intervened && reasons.size === 0) reasons.add('text:GUARDRAIL_INTERVENED');
  return { approved: !intervened, reasons: [...reasons] };
}

function isEnglishText(text) {
  // DetectToxicContent currently supports English only. Keep Korean and other
  // multilingual reviews on the Bedrock Guardrail path instead of failing them.
  return /^[\x00-\x7F]+$/.test(text) && /[A-Za-z]/.test(text);
}

async function translateToEnglish(text) {
  const normalized = text && text.trim();
  if (!normalized) return { text: '', sourceLanguage: null, translated: false };
  if (isEnglishText(normalized)) {
    return { text: normalized, sourceLanguage: 'en', translated: false };
  }

  const result = await translate.send(new TranslateTextCommand({
    Text: normalized,
    SourceLanguageCode: 'auto',
    TargetLanguageCode: 'en',
  }));
  if (!result.TranslatedText) throw new Error('Translate returned no English text');
  return {
    text: result.TranslatedText,
    sourceLanguage: result.SourceLanguageCode || 'auto',
    translated: true,
  };
}

async function checkComprehendToxicity(text) {
  const normalized = text && text.trim();
  if (!normalized || !isEnglishText(normalized)) return { approved: true, reasons: [] };

  // The Comprehend API accepts at most 1 KB per segment. ASCII is one byte per character.
  const result = await comprehend.send(new DetectToxicContentCommand({
    LanguageCode: 'en',
    TextSegments: [{ Text: normalized.slice(0, 1024) }],
  }));

  const toxicity = Number(result.ResultList?.[0]?.Toxicity || 0);
  const labels = (result.ResultList?.[0]?.Labels || [])
    .filter((label) => Number(label.Score || 0) >= COMPREHEND_TOXICITY_THRESHOLD)
    .map((label) => `text:COMPREHEND_${label.Name || 'TOXIC'}`);

  if (toxicity >= COMPREHEND_TOXICITY_THRESHOLD && labels.length === 0) {
    labels.push('text:COMPREHEND_TOXIC');
  }
  return { approved: labels.length === 0, reasons: labels };
}

async function checkImage(imageBucket, imageKey) {
  if (!imageBucket || !imageKey) return { approved: true, reasons: [] };
  const result = await rekognition.send(new DetectModerationLabelsCommand({
    Image: { S3Object: { Bucket: imageBucket, Name: imageKey } },
    MinConfidence: MIN_MODERATION_CONFIDENCE,
  }));
  const reasons = (result.ModerationLabels || []).map((label) => `image:${label.Name}`);
  return { approved: reasons.length === 0, reasons };
}

exports.handler = async (event) => {
  const { userId, productId, text, imageBucket, imageKey, moderationRequestId } = event || {};
  if (!userId || !productId || !moderationRequestId || !reviewsTableName) {
    throw new Error('review identity and PRODUCT_REVIEWS_TABLE_NAME are required');
  }
  let moderation;
  try {
    const english = await translateToEnglish(text);
    const [textResult, comprehendResult, imageResult] = await Promise.all([
      checkText(english.text),
      checkComprehendToxicity(english.text),
      checkImage(imageBucket, imageKey),
    ]);
    moderation = {
      approved: textResult.approved && comprehendResult.approved && imageResult.approved,
      reasons: [...textResult.reasons, ...comprehendResult.reasons, ...imageResult.reasons],
      sourceLanguage: english.sourceLanguage,
      translatedForModeration: english.translated,
    };
  } catch (err) {
    // Fail closed: unchecked content must never be persisted.
    console.error('moderation check failed', err);
    moderation = { approved: false, reasons: ['moderation_service_error'] };
  }

  const status = moderation.approved ? 'APPROVED' : 'REJECTED';
  const updateExpression = moderation.approved
    ? 'SET moderationStatus = :status, moderationReasons = :reasons, moderatedAt = :now REMOVE moderationExpiresAt'
    : 'SET moderationStatus = :status, moderationReasons = :reasons, moderatedAt = :now REMOVE moderationExpiresAt, photoUrl, photoKey';
  try {
    await dynamodb.send(new UpdateItemCommand({
      TableName: reviewsTableName,
      Key: { userId: { S: userId }, productId: { S: productId } },
      UpdateExpression: updateExpression,
      ConditionExpression: 'moderationRequestId = :requestId',
      ExpressionAttributeValues: {
        ':status': { S: status },
        ':reasons': { L: moderation.reasons.map((reason) => ({ S: reason })) },
        ':now': { S: new Date().toISOString() },
        ':requestId': { S: moderationRequestId },
      },
    }));
  } catch (err) {
    if (err.name === 'ConditionalCheckFailedException') {
      return { ignored: true, reason: 'stale_moderation_request', moderationRequestId };
    }
    throw err;
  }

  if (!moderation.approved && imageBucket && imageKey) {
    await s3.send(new DeleteObjectCommand({ Bucket: imageBucket, Key: imageKey }));
  }
  return { ...moderation, status, userId, productId, moderationRequestId };
};
