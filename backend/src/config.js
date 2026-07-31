module.exports = {
  port: process.env.PORT || 80,
  awsRegion: process.env.AWS_REGION,
  userPoolId: process.env.USER_POOL_ID,
  userPoolClientId: process.env.USER_POOL_CLIENT_ID,
  dynamodbTableName: process.env.DYNAMODB_TABLE_NAME,
};
