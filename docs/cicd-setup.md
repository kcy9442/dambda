# GitHub Actions deployment setup

The repository uses GitHub OIDC. Do not create long-lived AWS access keys. Run `terraform-bootstrap/` once with an administrator identity to create the state bucket and GitHub roles.

The bootstrap creates two IAM roles whose trust policy restricts `token.actions.githubusercontent.com:sub` to this repository:

- `AWS_PLAN_ROLE_ARN`: read access plus permissions required by `terraform plan`.
- `AWS_DEPLOY_ROLE_ARN`: infrastructure deployment, ECR push, and ECS deployment permissions.

Create GitHub environments `dev-plan` and `production`. Require reviewers on `production` and add these environment variables:

- `AWS_REGION` (`ap-northeast-2`)
- `AWS_PLAN_ROLE_ARN` or `AWS_DEPLOY_ROLE_ARN`
- `TF_STATE_BUCKET`
- `TF_STATE_KEY` (for example `dambda/production.tfstate`)
- `TF_STATE_REGION`
- `BEDROCK_GUARDRAIL_PROFILE_ARN` when the Standard tier requires cross-region inference
- `COST_ALERT_EMAIL` (required; receives AWS Budget and Cost Anomaly alerts)
- `MONTHLY_BUDGET_USD` (optional; defaults to `25`)
- `COST_ANOMALY_THRESHOLD_USD` (optional; defaults to `5`)

AWS Budget and Cost Anomaly Detection are enabled by default. Set
`ENABLE_COST_CONTROLS=false` only when intentionally disabling all cost alerts, or
`ENABLE_COST_ANOMALY_DETECTION=false` to keep the monthly budget while disabling
the anomaly monitor and subscription.

Add the rotated Tavily key as the `TAVILY_API_KEY` **secret** in the `production` environment. Never add it as a repository variable or commit it to `.env`. The deployment writes it to AWS Secrets Manager and ECS receives it through the task definition secret reference.

The state bucket must have versioning, encryption, public access blocking, and `s3:ListBucket`, `s3:GetObject`, `s3:PutObject`, and lock-file `s3:DeleteObject` permissions for the deployment roles.

Before enabling CI, remove already tracked generated files with `git rm --cached` (do not delete the local files if they are still needed):

```bash
git rm --cached terraform/*.tfplan terraform/*.tfstate terraform/*.tfstate.*
```

The first infrastructure bootstrap may need to run with ECS desired count zero until the ECR repository exists and the first `latest` image has been pushed. Subsequent deployments are fully handled by `deploy.yml`.
