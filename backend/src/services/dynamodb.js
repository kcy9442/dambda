const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');
const config = require('../config');

const client = DynamoDBDocumentClient.from(new DynamoDBClient({ region: config.awsRegion }));

async function putProfile(profile) {
  await client.send(
    new PutCommand({
      TableName: config.dynamodbTableName,
      Item: profile,
    })
  );
}

async function getProfile(userId) {
  const result = await client.send(
    new GetCommand({
      TableName: config.dynamodbTableName,
      Key: { userId },
    })
  );
  return result.Item;
}

module.exports = { putProfile, getProfile };
