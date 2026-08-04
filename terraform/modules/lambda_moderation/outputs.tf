output "lambda_arn" {
  description = "검열 Lambda ARN (ECS 태스크 역할 IAM 정책 스코프용)"
  value       = aws_lambda_function.moderation.arn
}

output "lambda_name" {
  description = "검열 Lambda 함수 이름 (백엔드가 InvokeCommand 호출 시 사용)"
  value       = aws_lambda_function.moderation.function_name
}
