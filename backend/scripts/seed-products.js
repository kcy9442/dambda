// 1회성 수동 스크립트. terraform apply로 product_catalog 테이블을 만든 뒤
// `AWS_REGION=ap-northeast-2 node backend/scripts/seed-products.js`로 직접 실행
// (AWS 자격증명 필요, translate:TranslateText 권한 포함).
const fs = require('fs');
const path = require('path');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');
const { TranslateClient, TranslateTextCommand } = require('@aws-sdk/client-translate');

const TABLE_NAME = process.env.PRODUCT_CATALOG_TABLE_NAME;
const AWS_REGION = process.env.AWS_REGION || 'ap-northeast-2';
const TERMINOLOGY_NAME = process.env.TRANSLATE_TERMINOLOGY_NAME;
const TARGET_LANGUAGES = ['en', 'ja', 'zh'];
const TRANSLATED_FIELDS = ['name', 'reason', 'store', 'discountInfo'];
const ITEMS_JSON_PATH = path.join(__dirname, '..', '..', 'json', 'items.json');

if (!TABLE_NAME) {
  console.error('PRODUCT_CATALOG_TABLE_NAME env var is required');
  process.exit(1);
}

// items.json은 유효한 단일 JSON이 아니라 배열 [...] 3개가 그냥 이어붙여진 텍스트라서
// ']' 다음에 '[' 가 나오는 지점을 기준으로 쪼개 각각 파싱한다.
function parseConcatenatedArrays(text) {
  const chunks = text.trim().split(/\]\s*\[/);
  return chunks.flatMap((chunk, index) => {
    const withOpen = index === 0 ? chunk : `[${chunk}`;
    const withClose = index === chunks.length - 1 ? withOpen : `${withOpen}]`;
    return JSON.parse(withClose);
  });
}

async function main() {
  const raw = fs.readFileSync(ITEMS_JSON_PATH, 'utf8');
  const items = parseConcatenatedArrays(raw);

  const client = DynamoDBDocumentClient.from(new DynamoDBClient({ region: AWS_REGION }));
  const translate = new TranslateClient({ region: AWS_REGION });
  const translationCache = new Map();

  async function translateText(text, targetLanguage) {
    if (!text || !String(text).trim()) return null;
    const cacheKey = `${targetLanguage}:${text}`;
    if (translationCache.has(cacheKey)) return translationCache.get(cacheKey);
    const request = translate.send(new TranslateTextCommand({
      Text: String(text),
      SourceLanguageCode: 'ko',
      TargetLanguageCode: targetLanguage,
      ...(TERMINOLOGY_NAME ? { TerminologyNames: [TERMINOLOGY_NAME] } : {}),
    })).then((result) => result.TranslatedText);
    translationCache.set(cacheKey, request);
    return request;
  }

  async function buildTranslations(item) {
    const languageEntries = await Promise.all(TARGET_LANGUAGES.map(async (language) => {
      const fieldEntries = await Promise.all(TRANSLATED_FIELDS.map(async (field) => {
        const translated = await translateText(item[field], language);
        return translated ? [field, translated] : null;
      }));
      return [language, Object.fromEntries(fieldEntries.filter(Boolean))];
    }));
    return Object.fromEntries(languageEntries);
  }

  for (const item of items) {
    const record = {
      itemId: item.itemId,
      category: item.category,
      name: item.name,
      price: item.price,
      store: item.store,
      reason: item.reason,
      imageUrl: item.imageUrl,
      translations: await buildTranslations(item),
      translatedAt: new Date().toISOString(),
    };
    if (item.discountInfo) record.discountInfo = item.discountInfo;

    await client.send(new PutCommand({ TableName: TABLE_NAME, Item: record }));
    console.log(`seeded and translated ${record.itemId}`);
  }

  console.log(`done - ${items.length} products written to ${TABLE_NAME}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
