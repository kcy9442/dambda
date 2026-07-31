output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.users.id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN (IAM 정책 스코프용)"
  value       = aws_cognito_user_pool.users.arn
}

output "user_pool_client_id" {
  description = "백엔드가 Admin* API 호출 시 사용할 App Client ID"
  value       = aws_cognito_user_pool_client.app_client.id
}
