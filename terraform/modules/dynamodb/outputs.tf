output "table_name" {
  description = "회원 프로필 DynamoDB 테이블 이름"
  value       = aws_dynamodb_table.user_profiles.name
}

output "table_arn" {
  description = "회원 프로필 DynamoDB 테이블 ARN (IAM 정책 스코프용)"
  value       = aws_dynamodb_table.user_profiles.arn
}

output "product_likes_table_name" {
  value = aws_dynamodb_table.product_likes.name
}

output "product_likes_table_arn" {
  value = aws_dynamodb_table.product_likes.arn
}

output "product_reviews_table_name" {
  value = aws_dynamodb_table.product_reviews.name
}

output "product_reviews_table_arn" {
  value = aws_dynamodb_table.product_reviews.arn
}

output "product_catalog_table_name" {
  value = aws_dynamodb_table.product_catalog.name
}

output "product_catalog_table_arn" {
  value = aws_dynamodb_table.product_catalog.arn
}
