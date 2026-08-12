data "aws_caller_identity" "current" {}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

resource "aws_cloudfront_function" "strip_api_prefix" {
  count   = var.api_origin_domain_name == "" ? 0 : 1
  name    = "${var.region_name}-strip-api-prefix"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = <<-EOT
    function handler(event) {
      var request = event.request;
      request.uri = request.uri.replace(/^\/api(?=\/|$)/, '') || '/';
      return request;
    }
  EOT
}

# 정적 웹 호스팅용 S3 버킷 (버킷 이름 전역 유일성 확보를 위해 계정 ID 접미사 사용)
resource "aws_s3_bucket" "static_site" {
  bucket = "${var.region_name}-static-site-${data.aws_caller_identity.current.account_id}"

  tags = { Name = "${var.region_name}-static-site" }
}

resource "aws_s3_bucket_public_access_block" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "static_site" {
  name                              = "${var.region_name}-static-site-oac"
  description                       = "Allow CloudFront signed access to the private static site bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontRead"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_site.arn}/*"
        Condition = {
          StringLike = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/*"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.static_site]
}

# Flutter 빌드가 배포한 index.html은 Terraform이 덮어쓰거나 삭제하지 않는다.
removed {
  from = aws_s3_object.index

  lifecycle {
    destroy = false
  }
}

resource "aws_cloudfront_distribution" "static_site" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_200"
  aliases             = var.custom_domain == "" ? [] : [var.custom_domain]

  origin {
    domain_name              = aws_s3_bucket.static_site.bucket_regional_domain_name
    origin_id                = "static-site-s3-website"
    origin_access_control_id = aws_cloudfront_origin_access_control.static_site.id

    s3_origin_config {
      origin_access_identity = ""
    }
  }

  dynamic "origin" {
    for_each = var.enable_failover_origin ? [1] : []
    content {
      domain_name              = var.failover_bucket_domain_name
      origin_id                = "static-site-s3-failover"
      origin_access_control_id = aws_cloudfront_origin_access_control.static_site.id
      s3_origin_config { origin_access_identity = "" }
    }
  }

  dynamic "origin" {
    for_each = var.api_origin_domain_name == "" ? [] : [1]
    content {
      domain_name = var.api_origin_domain_name
      origin_id   = "api-gateway"
      custom_header {
        name  = "X-Dambda-Origin-Verify"
        value = var.api_origin_verify_secret
      }
      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  dynamic "origin_group" {
    for_each = var.enable_failover_origin ? [1] : []
    content {
      origin_id = "static-site-origin-group"
      failover_criteria { status_codes = [403, 404, 500, 502, 503, 504] }
      member { origin_id = "static-site-s3-website" }
      member { origin_id = "static-site-s3-failover" }
    }
  }

  default_cache_behavior {
    target_origin_id       = var.enable_failover_origin ? "static-site-origin-group" : "static-site-s3-website"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.api_origin_domain_name == "" ? [] : [1]
    content {
      path_pattern             = "/api/*"
      target_origin_id         = "api-gateway"
      viewer_protocol_policy   = "redirect-to-https"
      allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods           = ["GET", "HEAD"]
      compress                 = true
      cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
      origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id
      function_association {
        event_type   = "viewer-request"
        function_arn = aws_cloudfront_function.strip_api_prefix[0].arn
      }
    }
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.acm_certificate_arn
    cloudfront_default_certificate = var.acm_certificate_arn == null
    ssl_support_method             = var.acm_certificate_arn == null ? null : "sni-only"
    minimum_protocol_version       = var.acm_certificate_arn == null ? null : "TLSv1.2_2021"
  }

  tags = { Name = "${var.region_name}-web" }
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

resource "aws_s3_bucket" "product_images" {
  bucket = "${var.region_name}-product-images-${data.aws_caller_identity.current.account_id}"
  tags   = { Name = "${var.region_name}-product-images" }
}

resource "aws_s3_bucket_public_access_block" "product_images" {
  bucket                  = aws_s3_bucket.product_images.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "product_images" {
  bucket = aws_s3_bucket.product_images.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow", Principal = "*", Action = "s3:GetObject",
      Resource = "${aws_s3_bucket.product_images.arn}/*"
    }]
  })
  depends_on = [aws_s3_bucket_public_access_block.product_images]
}

resource "aws_s3_bucket_cors_configuration" "product_images" {
  bucket = aws_s3_bucket.product_images.id
  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    allowed_headers = ["*"]
  }
}

