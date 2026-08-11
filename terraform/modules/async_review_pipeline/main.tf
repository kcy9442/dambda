resource "aws_sqs_queue" "review_dlq" {
  name                      = "${var.region_name}-review-events-dlq"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true

  tags = { Name = "${var.region_name}-review-events-dlq" }
}

resource "aws_sqs_queue" "review_events" {
  name                       = "${var.region_name}-review-events"
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = 345600
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.review_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = { Name = "${var.region_name}-review-events" }
}

resource "aws_iam_role" "state_machine" {
  name = "${var.region_name}-review-workflow-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "states.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "state_machine" {
  name = "${var.region_name}-review-workflow-policy"
  role = aws_iam_role.state_machine.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = var.moderation_lambda_arn
      },
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = aws_sqs_queue.review_events.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
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
    Comment = "Moderate a review, then enqueue approved review events for asynchronous consumers."
    StartAt = "ModerateReview"
    States = {
      ModerateReview = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = var.moderation_lambda_arn
          "Payload.$"  = "$"
        }
        ResultPath = "$.moderation"
        Next       = "IsApproved"
      }
      IsApproved = {
        Type = "Choice"
        Choices = [{
          Variable      = "$.moderation.Payload.approved"
          BooleanEquals = true
          Next          = "QueueApprovedReview"
        }]
        Default = "Rejected"
      }
      QueueApprovedReview = {
        Type     = "Task"
        Resource = "arn:aws:states:::sqs:sendMessage"
        Parameters = {
          QueueUrl        = aws_sqs_queue.review_events.id
          "MessageBody.$" = "$"
        }
        End = true
      }
      Rejected = { Type = "Fail", Error = "ReviewRejected", Cause = "Moderation rejected the review" }
    }
  })

  logging_configuration {
    include_execution_data = true
    level                  = "ERROR"
    log_destination        = "${aws_cloudwatch_log_group.state_machine.arn}:*"
  }

  tracing_configuration { enabled = true }

  tags = { Name = "${var.region_name}-review-moderation-workflow" }
}
