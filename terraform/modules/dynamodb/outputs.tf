output "table_name" {
  description = "회원 프로필 DynamoDB 테이블 이름"
  value       = aws_dynamodb_table.user_profiles.name
}

output "table_arn" {
  description = "회원 프로필 DynamoDB 테이블 ARN (IAM 정책 스코프용)"
  value       = aws_dynamodb_table.user_profiles.arn
}
