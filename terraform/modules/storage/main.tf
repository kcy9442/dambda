data "aws_caller_identity" "current" {}

# 정적 웹 호스팅용 S3 버킷 (버킷 이름 전역 유일성 확보를 위해 계정 ID 접미사 사용)
resource "aws_s3_bucket" "static_site" {
  bucket = "${var.region_name}-static-site-${data.aws_caller_identity.current.account_id}"

  tags = { Name = "${var.region_name}-static-site" }
}

resource "aws_s3_bucket_website_configuration" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# 테스트용: CloudFront 없이 버킷을 직접 퍼블릭으로 열어둠 (추후 CloudFront+OAC로 교체 예정)
resource "aws_s3_bucket_public_access_block" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_site.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.static_site]
}

# 배선 확인용 임시 테스트 페이지
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.static_site.id
  key          = "index.html"
  content_type = "text/html; charset=utf-8"
  content      = <<-EOT
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <title>Static Site Test</title>
      </head>
      <body>
        <h1>S3 정적 웹 호스팅 테스트 페이지</h1>
        <p>이 페이지가 보이면 S3 정적 웹 호스팅 배선이 정상입니다.</p>
      </body>
    </html>
  EOT
}

# 리뷰 사진 저장용 버킷. 퍼블릭 리드 - 민감정보 아니고 저장 전에 이미 Lambda로 검열을 거치므로
# presigned GET URL 같은 복잡도를 이 단계에서 들이지 않음. 업로드(PutObject)는 ECS 태스크 IAM으로만
# 허용 (버킷 정책이 아니라 IAM 정책 쪽에서 처리 - modules/compute 참고)
resource "aws_s3_bucket" "review_photos" {
  bucket = "${var.region_name}-review-photos-${data.aws_caller_identity.current.account_id}"

  tags = { Name = "${var.region_name}-review-photos" }
}

resource "aws_s3_bucket_public_access_block" "review_photos" {
  bucket = aws_s3_bucket.review_photos.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "review_photos" {
  bucket = aws_s3_bucket.review_photos.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.review_photos.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.review_photos]
}

# Flutter 웹(CanvasKit)은 이미지를 <img> 태그가 아니라 브라우저 fetch로 픽셀 데이터를 직접
# 받아와서 캔버스에 그리기 때문에, 버킷 정책상 공개 읽기여도 CORS 헤더가 없으면 브라우저가
# 응답을 막아버림 ("HTTP request failed") - API Gateway와 동일하게 테스트 단계라 전체 허용
resource "aws_s3_bucket_cors_configuration" "review_photos" {
  bucket = aws_s3_bucket.review_photos.id

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}
