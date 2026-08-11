# Operations, Security, and Cost Configuration

Terraform provisions the following components:

- CloudFront WAFv2 Web ACL with AWS common rules, IP reputation rules, and an IP rate limit.
- Encrypted SQS review-event queue and dead-letter queue.
- Step Functions review moderation workflow. It invokes the moderation Lambda and sends approved review events to SQS.
- Amazon Managed Prometheus workspace and a CloudWatch operations dashboard.
- Optional Amazon Managed Grafana workspace with CloudWatch and Prometheus data sources.
- Optional AWS Budget and daily Cost Anomaly Detection email alerts.

## Required GitHub Actions variables

Set these in **Settings → Secrets and variables → Actions → Variables** before a production deployment when the optional services are required.

| Variable | Example | Purpose |
| --- | --- | --- |
| `ENABLE_MANAGED_GRAFANA` | `true` | Creates the Grafana workspace. IAM Identity Center must already be enabled. |
| `ENABLE_COST_CONTROLS` | `true` | Enables Budget and Cost Anomaly Detection. |
| `COST_ALERT_EMAIL` | `your-email@example.com` | Receives budget and anomaly emails. |
| `MONTHLY_BUDGET_USD` | `25` | Monthly cost budget in USD. |
| `COST_ANOMALY_THRESHOLD_USD` | `5` | Daily anomaly impact threshold in USD. |

`ENABLE_MANAGED_GRAFANA` and `ENABLE_COST_CONTROLS` default to `false` so a deployment cannot accidentally create a workspace or send billing mail. Amazon Managed Prometheus defaults to enabled.

## Important integration note

The SQS queue and Step Functions workflow are provisioned, and the ECS task role has the permissions and environment variables needed to publish to them. The current review API intentionally continues its existing synchronous persistence flow until the backend route is migrated to asynchronous processing. This prevents a deployment of infrastructure alone from changing review behavior or losing reviews.
