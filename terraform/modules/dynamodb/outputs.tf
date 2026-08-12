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

output "product_catalog_stream_arn" {
  value = aws_dynamodb_table.product_catalog.stream_arn
}

output "us_table_arn" { value = replace(aws_dynamodb_table.user_profiles.arn, "ap-northeast-2", "us-east-1") }
output "us_product_likes_table_arn" { value = replace(aws_dynamodb_table.product_likes.arn, "ap-northeast-2", "us-east-1") }
output "us_product_reviews_table_arn" { value = replace(aws_dynamodb_table.product_reviews.arn, "ap-northeast-2", "us-east-1") }
output "us_product_catalog_table_arn" { value = replace(aws_dynamodb_table.product_catalog.arn, "ap-northeast-2", "us-east-1") }
