# 리뷰 등록 시 백엔드(ECS)가 동기 호출하는 검열 함수 (Rekognition 이미지 + Comprehend 텍스트).
# Docker/ECR 안 씀 - Lambda라 이미지가 필요 없고, terraform apply 한 번으로 배포까지 끝남 (수동 배포 불필요)
data "archive_file" "moderation_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/moderation"
  output_path = "${path.module}/moderation_lambda.zip"
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
        Action   = ["rekognition:DetectModerationLabels", "comprehend:DetectToxicContent"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = "${var.review_photos_bucket_arn}/*"
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
  timeout       = 10

  filename         = data.archive_file.moderation_lambda.output_path
  source_code_hash = data.archive_file.moderation_lambda.output_base64sha256
}
