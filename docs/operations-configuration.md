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

## Cost allocation tags

Terraform applies `Project=DAMBDA`, `Environment=dev`, `ManagedBy=Terraform`,
`Repository=dambda`, and `CostCenter=DAMBDA` to every AWS resource type that
supports tags in both regions. In AWS Billing, activate the `Project`,
`Environment`, and `CostCenter` user-defined cost allocation tags before using
them to group or filter costs in Cost Explorer. Tag activation and cost data
can take up to 24 hours to appear. The monthly AWS Budget remains account-wide
so untaggable shared AWS charges are not accidentally omitted.

## Important integration note

The review API stores a pending review, publishes its moderation request to
SQS, and EventBridge Pipes starts the Step Functions moderation workflow. Only
reviews changed to `APPROVED` by the worker Lambda are returned in public review
lists.
