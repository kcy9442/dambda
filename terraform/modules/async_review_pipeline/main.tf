resource "aws_sqs_queue" "review_dlq" {
  name                      = "${var.region_name}-review-moderation-dlq"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true
}

resource "aws_sqs_queue" "review_events" {
  name                       = "${var.region_name}-review-moderation-requests"
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = 345600
  sqs_managed_sse_enabled    = true
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.review_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
}

resource "aws_iam_role" "state_machine" {
  name = "${var.region_name}-review-workflow-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "sts:AssumeRole", Principal = { Service = "states.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "state_machine" {
  name = "${var.region_name}-review-workflow-policy"
  role = aws_iam_role.state_machine.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = "lambda:InvokeFunction", Resource = var.moderation_lambda_arn },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery", "logs:GetLogDelivery", "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery", "logs:ListLogDeliveries", "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies", "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "state_machine" {
  name              = "/aws/vendedlogs/states/${var.region_name}-review-moderation"
  retention_in_days = 30
}

resource "aws_sfn_state_machine" "review_moderation" {
  name     = "${var.region_name}-review-moderation-workflow"
  role_arn = aws_iam_role.state_machine.arn
  type     = "STANDARD"
  definition = jsonencode({
    Comment = "Moderate a pending review and persist its final status."
    StartAt = "ModerateReview"
    States = {
      ModerateReview = {
        Type       = "Task", Resource = "arn:aws:states:::lambda:invoke"
        Parameters = { FunctionName = var.moderation_lambda_arn, "Payload.$" = "$" }
        Retry = [{
          ErrorEquals     = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"]
          IntervalSeconds = 2, MaxAttempts = 3, BackoffRate = 2
        }]
        OutputPath = "$.Payload", End = true
      }
    }
  })
  logging_configuration {
    include_execution_data = true
    level                  = "ERROR"
    log_destination        = "${aws_cloudwatch_log_group.state_machine.arn}:*"
  }
  tracing_configuration { enabled = true }
}

resource "aws_iam_role" "pipe" {
  name = "${var.region_name}-review-moderation-pipe-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "sts:AssumeRole", Principal = { Service = "pipes.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "pipe" {
  name = "${var.region_name}-review-moderation-pipe-policy"
  role = aws_iam_role.pipe.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"], Resource = aws_sqs_queue.review_events.arn },
      { Effect = "Allow", Action = "states:StartExecution", Resource = aws_sfn_state_machine.review_moderation.arn }
    ]
  })
}

resource "aws_pipes_pipe" "review_moderation" {
  name     = "${var.region_name}-review-moderation"
  role_arn = aws_iam_role.pipe.arn
  source   = aws_sqs_queue.review_events.arn
  target   = aws_sfn_state_machine.review_moderation.arn
  source_parameters {
    sqs_queue_parameters {
      batch_size = 1
    }
  }
  target_parameters {
    input_template = "<$.body>"
  }
}
