resource "aws_acm_certificate" "api_seoul" {
  provider          = aws.seoul
  domain_name       = var.api_domain
  validation_method = "DNS"
  lifecycle { create_before_destroy = true }
}

resource "aws_acm_certificate" "api_us" {
  provider          = aws.us_east_1
  domain_name       = var.api_domain
  validation_method = "DNS"
  lifecycle { create_before_destroy = true }
}

resource "aws_route53_record" "api_certificate_validation" {
  provider        = aws.seoul
  zone_id         = data.aws_route53_zone.primary.zone_id
  name            = one(aws_acm_certificate.api_seoul.domain_validation_options).resource_record_name
  type            = one(aws_acm_certificate.api_seoul.domain_validation_options).resource_record_type
  records         = [one(aws_acm_certificate.api_seoul.domain_validation_options).resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "api_seoul" {
  provider                = aws.seoul
  certificate_arn         = aws_acm_certificate.api_seoul.arn
  validation_record_fqdns = [aws_route53_record.api_certificate_validation.fqdn]
}

resource "aws_acm_certificate_validation" "api_us" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.api_us.arn
  validation_record_fqdns = [aws_route53_record.api_certificate_validation.fqdn]
}

resource "aws_apigatewayv2_domain_name" "api_seoul" {
  provider    = aws.seoul
  domain_name = var.api_domain
  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.api_seoul.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_domain_name" "api_us" {
  provider    = aws.us_east_1
  domain_name = var.api_domain
  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.api_us.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "api_seoul" {
  provider    = aws.seoul
  api_id      = module.api_gateway.api_id
  domain_name = aws_apigatewayv2_domain_name.api_seoul.id
  stage       = "$default"
}

resource "aws_apigatewayv2_api_mapping" "api_us" {
  provider    = aws.us_east_1
  api_id      = module.api_gateway_us.api_id
  domain_name = aws_apigatewayv2_domain_name.api_us.id
  stage       = "$default"
}

resource "aws_route53_health_check" "api_seoul" {
  provider          = aws.seoul
  fqdn              = trimsuffix(trimprefix(module.api_gateway.api_endpoint, "https://"), "/")
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  request_interval  = 30
  failure_threshold = 3
  tags              = { Name = "${var.region_name}-api-health" }
}

resource "aws_route53_record" "api_primary" {
  provider        = aws.seoul
  zone_id         = data.aws_route53_zone.primary.zone_id
  name            = var.api_domain
  type            = "A"
  set_identifier  = "seoul-primary"
  health_check_id = aws_route53_health_check.api_seoul.id
  failover_routing_policy { type = "PRIMARY" }
  alias {
    name                   = aws_apigatewayv2_domain_name.api_seoul.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_seoul.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "api_secondary" {
  provider       = aws.seoul
  zone_id        = data.aws_route53_zone.primary.zone_id
  name           = var.api_domain
  type           = "A"
  set_identifier = "us-secondary"
  failover_routing_policy { type = "SECONDARY" }
  alias {
    name                   = aws_apigatewayv2_domain_name.api_us.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_us.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = true
  }
}
