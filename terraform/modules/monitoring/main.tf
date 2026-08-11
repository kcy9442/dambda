resource "aws_prometheus_workspace" "main" {
  count = var.enable_prometheus ? 1 : 0
  alias = "${var.region_name}-amp"

  tags = { Name = "${var.region_name}-amp" }
}

resource "aws_grafana_workspace" "main" {
  count = var.enable_grafana ? 1 : 0

  name                     = "${var.region_name}-observability"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  data_sources             = ["CLOUDWATCH", "PROMETHEUS"]
  role_arn                 = aws_iam_role.grafana_workspace[0].arn

  depends_on = [aws_iam_role_policy.grafana_workspace]

  tags = { Name = "${var.region_name}-observability" }
}

resource "aws_iam_role" "grafana_workspace" {
  count = var.enable_grafana ? 1 : 0
  name  = "${var.region_name}-grafana-workspace-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "grafana.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "grafana_workspace" {
  count = var.enable_grafana ? 1 : 0
  name  = "${var.region_name}-grafana-data-source-read"
  role  = aws_iam_role.grafana_workspace[0].id

  # The workspace role is assumed by Amazon Managed Grafana to query its
  # configured CloudWatch and AMP data sources.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:StartQuery",
          "logs:GetQueryResults",
          "logs:StopQuery",
          "tag:GetResources",
          "aps:GetLabels",
          "aps:GetMetricMetadata",
          "aps:GetSeries",
          "aps:QueryMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudwatch_dashboard" "operations" {
  dashboard_name = "${var.region_name}-operations"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ECS service CPU and memory"
          region = var.aws_region
          stat   = "Average"
          period = 300
          view   = "timeSeries"
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Review moderation Lambda"
          region = var.aws_region
          stat   = "Sum"
          period = 300
          view   = "timeSeries"
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", var.moderation_lambda_name],
            [".", "Errors", ".", "."]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        properties = {
          title  = "Review event queue"
          region = var.aws_region
          stat   = "Maximum"
          period = 300
          view   = "timeSeries"
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.review_queue_name],
            [".", "ApproximateAgeOfOldestMessage", ".", "."]
          ]
        }
      }
    ]
  })
}
