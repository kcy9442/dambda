const { BedrockRuntimeClient, ApplyGuardrailCommand } = require('@aws-sdk/client-bedrock-runtime');
const { RekognitionClient, DetectModerationLabelsCommand } = require('@aws-sdk/client-rekognition');

const region = process.env.AWS_REGION;
const guardrailId = process.env.BEDROCK_GUARDRAIL_ID;
const guardrailVersion = process.env.BEDROCK_GUARDRAIL_VERSION;
const bedrock = new BedrockRuntimeClient({ region });
const rekognition = new RekognitionClient({ region });
const MIN_MODERATION_CONFIDENCE = 70;

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
  const { text, imageBucket, imageKey } = event || {};
  try {
    const [textResult, imageResult] = await Promise.all([
      checkText(text),
      checkImage(imageBucket, imageKey),
    ]);
    return {
      approved: textResult.approved && imageResult.approved,
      reasons: [...textResult.reasons, ...imageResult.reasons],
    };
  } catch (err) {
    // Fail closed: unchecked content must never be persisted.
    console.error('moderation check failed', err);
    return { approved: false, reasons: ['moderation_service_error'] };
  }
};
