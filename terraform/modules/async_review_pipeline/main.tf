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

# EventBridge is the event contract for downstream consumers.  New consumers
# can subscribe with their own rules without changing the review workflow.
resource "aws_cloudwatch_event_bus" "review_events" {
  name = "${var.region_name}-review-events"
  tags = { Name = "${var.region_name}-review-events" }
}

resource "aws_cloudwatch_event_rule" "approved_review_to_sqs" {
  name           = "${var.region_name}-approved-review-to-sqs"
  event_bus_name = aws_cloudwatch_event_bus.review_events.name

  event_pattern = jsonencode({
    source        = ["dambda.reviews"]
    "detail-type" = ["ReviewApproved"]
  })
}

resource "aws_cloudwatch_event_target" "approved_review_queue" {
  rule           = aws_cloudwatch_event_rule.approved_review_to_sqs.name
  event_bus_name = aws_cloudwatch_event_bus.review_events.name
  arn            = aws_sqs_queue.review_events.arn
}

resource "aws_sqs_queue_policy" "allow_eventbridge" {
  queue_url = aws_sqs_queue.review_events.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowEventBridgeToSendApprovedReviews"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.review_events.arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = aws_cloudwatch_event_rule.approved_review_to_sqs.arn }
      }
    }]
  })
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
        Action   = ["events:PutEvents"]
        Resource = aws_cloudwatch_event_bus.review_events.arn
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
          Next          = "PublishApprovedReview"
        }]
        Default = "Rejected"
      }
      PublishApprovedReview = {
        Type     = "Task"
        Resource = "arn:aws:states:::events:putEvents"
        Parameters = {
          Entries = [{
            Source       = "dambda.reviews"
            DetailType   = "ReviewApproved"
            EventBusName = aws_cloudwatch_event_bus.review_events.name
            "Detail.$"   = "States.JsonToString($)"
          }]
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
