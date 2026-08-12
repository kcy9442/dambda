# 리뷰 등록 시 백엔드(ECS)가 동기 호출하는 검열 함수 (Rekognition 이미지 + Comprehend 텍스트).
# Docker/ECR 안 씀 - Lambda라 이미지가 필요 없고, terraform apply 한 번으로 배포까지 끝남 (수동 배포 불필요)
data "archive_file" "moderation_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/moderation"
  output_path = "${path.module}/moderation_lambda.zip"
}

locals {
  guardrail_filter_types = ["HATE", "INSULTS", "SEXUAL", "VIOLENCE", "MISCONDUCT"]
}

resource "aws_bedrock_guardrail" "reviews" {
  name                      = "${var.region_name}-review-moderation"
  description               = "Multilingual moderation for DAMBDA product reviews"
  blocked_input_messaging   = "등록할 수 없는 내용이 포함되어 있습니다."
  blocked_outputs_messaging = "차단된 내용입니다."

  content_policy_config {
    dynamic "filters_config" {
      for_each = toset(local.guardrail_filter_types)
      content {
        type            = filters_config.value
        input_strength  = "MEDIUM"
        output_strength = "MEDIUM"
      }
    }
    dynamic "tier_config" {
      for_each = var.guardrail_profile_identifier == "" ? [] : [1]
      content {
        tier_name = "STANDARD"
      }
    }
  }

  sensitive_information_policy_config {
    pii_entities_config {
      action = "BLOCK"
      type   = "EMAIL"
    }
    pii_entities_config {
      action = "BLOCK"
      type   = "PHONE"
    }
  }

  dynamic "cross_region_config" {
    for_each = var.guardrail_profile_identifier == "" ? [] : [var.guardrail_profile_identifier]
    content {
      guardrail_profile_identifier = cross_region_config.value
    }
  }

  tags = { Name = "${var.region_name}-review-moderation" }
}

resource "aws_bedrock_guardrail_version" "reviews" {
  guardrail_arn = aws_bedrock_guardrail.reviews.guardrail_arn
  description   = "Managed by Terraform"
  skip_destroy  = true
}

resource "aws_iam_role" "moderation_lambda_role" {
  name = "${var.region_name}-moderation-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "moderation_lambda_logs" {
  role       = aws_iam_role.moderation_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "moderation_lambda_policy" {
  name = "${var.region_name}-moderation-lambda-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Rekognition/Comprehend는 리소스 레벨 ARN을 지원하지 않는 AWS API 자체의 제약 - "*"가 맞음
        Action = [
          "rekognition:DetectModerationLabels",
          "comprehend:DetectToxicContent",
          "comprehend:DetectDominantLanguage",
          "translate:TranslateText",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = ["bedrock:ApplyGuardrail"]
        Effect   = "Allow"
        Resource = [aws_bedrock_guardrail.reviews.guardrail_arn, "${aws_bedrock_guardrail.reviews.guardrail_arn}/*"]
      },
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = "${var.review_photos_bucket_arn}/*"
      },
      {
        Action   = ["s3:DeleteObject"]
        Effect   = "Allow"
        Resource = "${var.review_photos_bucket_arn}/*"
      },
      {
        Action   = ["dynamodb:UpdateItem"]
        Effect   = "Allow"
        Resource = var.product_reviews_table_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "moderation_lambda_permissions" {
  role       = aws_iam_role.moderation_lambda_role.name
  policy_arn = aws_iam_policy.moderation_lambda_policy.arn
}

resource "aws_lambda_function" "moderation" {
  function_name = "${var.region_name}-review-moderation"
  role          = aws_iam_role.moderation_lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  # Translate, Bedrock Guardrails, Comprehend, and Rekognition can exceed ten
  # seconds during cold starts. Keep this below the review queue's 300-second
  # visibility timeout while allowing enough time for the complete workflow.
  timeout = 30

  filename         = data.archive_file.moderation_lambda.output_path
  source_code_hash = data.archive_file.moderation_lambda.output_base64sha256

  environment {
    variables = {
      BEDROCK_GUARDRAIL_ID          = aws_bedrock_guardrail.reviews.guardrail_id
      BEDROCK_GUARDRAIL_VERSION     = aws_bedrock_guardrail_version.reviews.version
      COMPREHEND_TOXICITY_THRESHOLD = "0.80"
      PRODUCT_REVIEWS_TABLE_NAME    = var.product_reviews_table_name
    }
  }
}
