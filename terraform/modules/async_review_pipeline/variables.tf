variable "region_name" {
  type = string
}

variable "moderation_lambda_arn" {
  type = string
}

variable "visibility_timeout_seconds" {
  type    = number
  default = 300
}

variable "max_receive_count" {
  type    = number
  default = 5
}
