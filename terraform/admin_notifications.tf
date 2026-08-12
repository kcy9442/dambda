resource "aws_sns_topic" "product_changes" {
  provider = aws.seoul
  name     = "${var.region_name}-product-changes"
}

resource "aws_sns_topic_subscription" "product_changes_email" {
  provider  = aws.seoul
  topic_arn = aws_sns_topic.product_changes.arn
  protocol  = "email"
  endpoint  = var.cost_alert_email
}

resource "aws_iam_role" "product_change_pipe" {
  provider = aws.seoul
  name     = "${var.region_name}-product-change-pipe-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow", Action = "sts:AssumeRole"
      Principal = { Service = "pipes.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "product_change_pipe" {
  provider = aws.seoul
  name     = "${var.region_name}-product-change-pipe-policy"
  role     = aws_iam_role.product_change_pipe.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:DescribeStream", "dynamodb:GetRecords", "dynamodb:GetShardIterator", "dynamodb:ListStreams"]
        Resource = module.dynamodb.product_catalog_stream_arn
      },
      { Effect = "Allow", Action = "sns:Publish", Resource = aws_sns_topic.product_changes.arn }
    ]
  })
}

resource "aws_pipes_pipe" "product_changes" {
  provider = aws.seoul
  name     = "${var.region_name}-product-changes"
  role_arn = aws_iam_role.product_change_pipe.arn
  source   = module.dynamodb.product_catalog_stream_arn
  target   = aws_sns_topic.product_changes.arn

  source_parameters {
    dynamodb_stream_parameters {
      starting_position = "LATEST"
      batch_size        = 1
    }
  }
}
