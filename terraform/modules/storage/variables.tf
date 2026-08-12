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

variable "failover_bucket_domain_name" {
  description = "Optional cross-region S3 origin used by CloudFront origin failover"
  type        = string
  default     = ""
}

variable "enable_failover_origin" {
  description = "Whether to configure the secondary S3 origin and CloudFront origin group"
  type        = bool
  default     = false
}

variable "api_origin_domain_name" {
  type    = string
  default = ""
}

variable "api_origin_verify_secret" {
  type      = string
  sensitive = true
  default   = ""
}
