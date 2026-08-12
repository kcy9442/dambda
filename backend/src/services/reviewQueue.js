const { SQSClient, SendMessageCommand } = require('@aws-sdk/client-sqs');
const config = require('../config');

const client = new SQSClient({ region: config.resourceRegion });

async function enqueueModeration(review) {
  if (!config.reviewEventsQueueUrl) throw new Error('REVIEW_EVENTS_QUEUE_URL is required');
  await client.send(new SendMessageCommand({
    QueueUrl: config.reviewEventsQueueUrl,
    MessageBody: JSON.stringify({
      userId: review.userId,
      productId: review.productId,
      text: review.text,
      imageBucket: review.photoKey ? config.reviewPhotosBucket : null,
      imageKey: review.photoKey,
      moderationRequestId: review.moderationRequestId,
    }),
  }));
}

module.exports = { enqueueModeration };
