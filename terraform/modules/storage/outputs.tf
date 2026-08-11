output "bucket_name" {
  description = "정적 웹 호스팅 S3 버킷 이름"
  value       = aws_s3_bucket.static_site.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for cache invalidation"
  value       = aws_cloudfront_distribution.static_site.id
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.static_site.domain_name
}

output "cloudfront_distribution_arn" {
  value = aws_cloudfront_distribution.static_site.arn
}

output "cloudfront_hosted_zone_id" {
  value = aws_cloudfront_distribution.static_site.hosted_zone_id
}

output "website_endpoint" {
  description = "CloudFront HTTPS 웹 사이트 URL"
  value       = "https://${aws_cloudfront_distribution.static_site.domain_name}"
}

output "s3_website_endpoint" {
  description = "원본 S3 정적 웹 호스팅 엔드포인트 URL"
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

output "product_images_bucket_name" { value = aws_s3_bucket.product_images.id }
output "product_images_bucket_arn" { value = aws_s3_bucket.product_images.arn }
output "product_images_bucket_domain" { value = aws_s3_bucket.product_images.bucket_regional_domain_name }

