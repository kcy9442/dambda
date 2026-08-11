variable "region_name" {
  type = string
}

variable "rate_limit_per_5_minutes" {
  description = "Maximum requests per source IP during a five-minute WAF evaluation window"
  type        = number
  default     = 2000
}
