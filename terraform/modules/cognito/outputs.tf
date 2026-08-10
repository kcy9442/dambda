output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.users.id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.users.arn
}

output "user_pool_client_id" {
  description = "Cognito App Client ID"
  value       = aws_cognito_user_pool_client.app_client.id
}

output "oauth_domain" {
  description = "Cognito OAuth managed-login domain"
  value       = "https://${aws_cognito_user_pool_domain.login.domain}.auth.ap-northeast-2.amazoncognito.com"
}

output "social_provider_callback_url" {
  description = "OAuth identity-provider callback URL"
  value       = "https://${aws_cognito_user_pool_domain.login.domain}.auth.ap-northeast-2.amazoncognito.com/oauth2/idpresponse"
}
