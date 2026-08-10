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

variable "cors_allowed_origins" {
  description = "CORS 허용 오리진. 테스트 단계라 기본값은 전체 허용(S3 버킷도 지금 전체 공개 상태라 위험 수준 일관됨)"
  type        = list(string)
  default     = ["*"]
}