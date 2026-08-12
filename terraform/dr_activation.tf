data "archive_file" "dr_failover" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/dr-failover"
  output_path = "${path.module}/.tmp/dr-failover.zip"
}

resource "aws_sns_topic" "dr_failover" {
  provider = aws.us_east_1
  name     = "${var.region_name}-dr-failover"
}

resource "aws_iam_role" "dr_failover" {
  provider = aws.us_east_1
  name     = "${var.region_name}-dr-failover-lambda-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "sts:AssumeRole", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "dr_failover_logs" {
  provider   = aws.us_east_1
  role       = aws_iam_role.dr_failover.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "dr_failover" {
  provider = aws.us_east_1
  name     = "${var.region_name}-dr-failover"
  role     = aws_iam_role.dr_failover.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ecs:UpdateService"]
      Resource = "arn:aws:ecs:${var.us_aws_region}:${data.aws_caller_identity.current.account_id}:service/${module.compute_us.cluster_name}/${module.compute_us.service_name}"
    }]
  })
}

resource "aws_lambda_function" "dr_failover" {
  provider         = aws.us_east_1
  function_name    = "${var.region_name}-dr-failover"
  role             = aws_iam_role.dr_failover.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout          = 30
  filename         = data.archive_file.dr_failover.output_path
  source_code_hash = data.archive_file.dr_failover.output_base64sha256
  environment {
    variables = {
      ECS_CLUSTER = module.compute_us.cluster_name
      ECS_SERVICE = module.compute_us.service_name
    }
  }
}

resource "aws_lambda_permission" "dr_failover_sns" {
  provider      = aws.us_east_1
  statement_id  = "AllowFailoverSns"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dr_failover.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.dr_failover.arn
}

resource "aws_sns_topic_subscription" "dr_failover_lambda" {
  provider  = aws.us_east_1
  topic_arn = aws_sns_topic.dr_failover.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.dr_failover.arn
}

resource "aws_cloudwatch_metric_alarm" "primary_api_health" {
  provider            = aws.us_east_1
  alarm_name          = "${var.region_name}-primary-api-unhealthy"
  namespace           = "AWS/Route53"
  metric_name         = "HealthCheckStatus"
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"
  dimensions          = { HealthCheckId = aws_route53_health_check.api_seoul.id }
  alarm_actions       = [aws_sns_topic.dr_failover.arn]
  ok_actions          = [aws_sns_topic.dr_failover.arn]
}
