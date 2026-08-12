variable "region_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "moderation_lambda_name" {
  type = string
}

variable "review_queue_name" {
  type = string
}

variable "review_dlq_name" { type = string }
variable "api_gateway_id" { type = string }

variable "enable_prometheus" {
  type    = bool
  default = true
}

variable "enable_grafana" {
  type    = bool
  default = false
}
