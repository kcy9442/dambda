const { ScanCommand, GetCommand, PutCommand, DeleteCommand } = require('@aws-sdk/lib-dynamodb');
const config = require('../config');
const client = require('./dynamoClient');

async function listProducts() {
  const result = await client.send(
    new ScanCommand({ TableName: config.productCatalogTableName })
  );
  return (result.Items || []).sort(
    (a, b) => a.category.localeCompare(b.category) || a.name.localeCompare(b.name)
  );
}

async function putProduct(product) {
  await client.send(new PutCommand({
    TableName: config.productCatalogTableName,
    Item: product,
    ConditionExpression: 'attribute_not_exists(itemId)',
  }));
}

async function getProduct(itemId) {
  const result = await client.send(new GetCommand({
    TableName: config.productCatalogTableName,
    Key: { itemId },
  }));
  return result.Item || null;
}

async function updateProduct(product) {
  await client.send(new PutCommand({
    TableName: config.productCatalogTableName,
    Item: product,
    ConditionExpression: 'attribute_exists(itemId)',
  }));
}

async function deleteProduct(itemId) {
  await client.send(new DeleteCommand({
    TableName: config.productCatalogTableName,
    Key: { itemId },
    ConditionExpression: 'attribute_exists(itemId)',
  }));
}

module.exports = { listProducts, putProduct, getProduct, updateProduct, deleteProduct };
