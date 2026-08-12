resource "random_password" "cloudfront_origin" {
  length  = 48
  special = false
}

resource "aws_secretsmanager_secret" "cloudfront_origin_seoul" {
  provider                = aws.seoul
  name                    = "${var.region_name}/cloudfront-origin-verify"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "cloudfront_origin_seoul" {
  provider      = aws.seoul
  secret_id     = aws_secretsmanager_secret.cloudfront_origin_seoul.id
  secret_string = random_password.cloudfront_origin.result
}

resource "aws_secretsmanager_secret" "cloudfront_origin_us" {
  provider                = aws.us_east_1
  name                    = "${var.us_region_name}/cloudfront-origin-verify"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "cloudfront_origin_us" {
  provider      = aws.us_east_1
  secret_id     = aws_secretsmanager_secret.cloudfront_origin_us.id
  secret_string = random_password.cloudfront_origin.result
}
