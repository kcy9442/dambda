data "aws_route53_zone" "primary" {
  provider     = aws.seoul
  name         = var.root_domain
  private_zone = false
}

# CloudFront requires its ACM certificate to be created in us-east-1.
resource "aws_acm_certificate" "web" {
  provider          = aws.us_east_1
  domain_name       = var.web_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "web_certificate_validation" {
  provider = aws.seoul
  for_each = {
    for option in aws_acm_certificate.web.domain_validation_options : option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  }

  zone_id         = data.aws_route53_zone.primary.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "web" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.web.arn
  validation_record_fqdns = [for record in aws_route53_record.web_certificate_validation : record.fqdn]
}

resource "aws_route53_record" "web_ipv4" {
  provider = aws.seoul
  zone_id  = data.aws_route53_zone.primary.zone_id
  name     = var.web_domain
  type     = "A"

  alias {
    name                   = module.storage.cloudfront_domain_name
    zone_id                = module.storage.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "web_ipv6" {
  provider = aws.seoul
  zone_id  = data.aws_route53_zone.primary.zone_id
  name     = var.web_domain
  type     = "AAAA"

  alias {
    name                   = module.storage.cloudfront_domain_name
    zone_id                = module.storage.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}
