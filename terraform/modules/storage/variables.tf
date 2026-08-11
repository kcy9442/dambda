variable "region_name" {
  description = "리소스 이름 태그용 접두어"
  type        = string
}

variable "custom_domain" {
  description = "Optional custom hostname for the CloudFront distribution"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN from us-east-1 for the custom hostname"
  type        = string
  default     = null
}

variable "waf_web_acl_arn" {
  description = "Optional CloudFront-scope WAFv2 Web ACL ARN"
  type        = string
  default     = null
}
