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

  tags = { Name = "${var.region_name}-observability" }
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
