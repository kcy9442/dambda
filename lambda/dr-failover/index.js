const { ECSClient, UpdateServiceCommand } = require('@aws-sdk/client-ecs');

const ecs = new ECSClient({});

exports.handler = async (event) => {
  const message = JSON.parse(event.Records[0].Sns.Message);
  const desiredCount = message.NewStateValue === 'ALARM' ? 1 : 0;
  await ecs.send(new UpdateServiceCommand({
    cluster: process.env.ECS_CLUSTER,
    service: process.env.ECS_SERVICE,
    desiredCount,
  }));
  return { desiredCount, alarmState: message.NewStateValue };
};
