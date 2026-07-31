variable "region_name" {
  type = string
}

variable "vpc_id" {
  description = "VPC Link ENI 보안 그룹이 생성될 VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "VPC Link ENI가 배치될 프라이빗 서브넷 ID 리스트"
  type        = list(string)
}

variable "alb_listener_arn" {
  description = "내부 ALB HTTP 리스너 ARN (HTTP_PROXY 통합 대상)"
  type        = string
}