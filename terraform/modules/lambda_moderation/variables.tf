variable "region_name" {
  description = "리소스 이름 태그용 접두어"
  type        = string
}

variable "review_photos_bucket_arn" {
  description = "리뷰 사진 S3 버킷 ARN (Lambda 실행 역할이 GetObject 하기 위함)"
  type        = string
}
