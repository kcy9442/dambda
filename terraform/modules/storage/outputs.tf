output "bucket_name" {
  description = "정적 웹 호스팅 S3 버킷 이름"
  value       = aws_s3_bucket.static_site.id
}

output "website_endpoint" {
  description = "S3 정적 웹 호스팅 엔드포인트 URL"
  value       = "http://${aws_s3_bucket_website_configuration.static_site.website_endpoint}"
}

output "review_photos_bucket_name" {
  description = "리뷰 사진 저장 S3 버킷 이름"
  value       = aws_s3_bucket.review_photos.id
}

output "review_photos_bucket_arn" {
  description = "리뷰 사진 저장 S3 버킷 ARN (IAM 정책 스코프용)"
  value       = aws_s3_bucket.review_photos.arn
}

output "review_photos_bucket_regional_domain" {
  description = "리뷰 사진 공개 URL 조립용 (https://<domain>/<key>)"
  value       = aws_s3_bucket.review_photos.bucket_regional_domain_name
}
