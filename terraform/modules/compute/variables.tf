variable "region_name" {
  description = "리소스 이름 태그용 접두어"
  type        = string
}

variable "vpc_id" {
  description = "ECS가 배치될 VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "ECS 서비스가 배포될 프라이빗 서브넷 ID 리스트"
  type        = list(string)
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
}

variable "alb_security_group_id" {
  description = "ALB의 보안 그룹 ID (ECS 보안 그룹에서 허용하기 위함)"
  type        = string
}

variable "target_group_arn" {
  description = "ALB 대상 그룹 ARN (ECS 서비스 등록용)"
  type        = string
}

variable "container_port" {
  description = "컨테이너가 리스닝할 포트"
  type        = number
  default     = 80
}

variable "desired_count" {
  description = "평소 유지할 ECS 태스크 개수 (pilot light DR 리전은 0으로 설정)"
  type        = number
  default     = 2
}

variable "autoscaling_min_capacity" {
  description = "오토스케일링 최소 태스크 개수 (pilot light DR 리전은 0으로 설정)"
  type        = number
  default     = 2
}

variable "autoscaling_max_capacity" {
  description = "오토스케일링 최대 태스크 개수 (재해 전환 시 실제로 받을 트래픽 기준)"
  type        = number
  default     = 5
}

# 로그인/회원가입 백엔드용 (Cognito + DynamoDB). 기본값 빈 문자열 -
# us-east-1 pilot light(compute_us, desired_count=0)는 아직 자체 Cognito/DynamoDB가 없어서
# 이 값들을 넘기지 않음. 실제로 DR을 활성화할 때(Phase 7) 미국 리전에도 만들어 넘겨야 함
variable "user_pool_id" {
  description = "백엔드가 Admin* API 호출 시 사용할 Cognito User Pool ID"
  type        = string
  default     = ""
}

variable "user_pool_arn" {
  description = "Cognito User Pool ARN (태스크 역할 IAM 정책 스코프용)"
  type        = string
  default     = ""
}

variable "user_pool_client_id" {
  description = "Cognito App Client ID"
  type        = string
  default     = ""
}

variable "dynamodb_table_name" {
  description = "회원 프로필 DynamoDB 테이블 이름"
  type        = string
  default     = ""
}

variable "dynamodb_table_arn" {
  description = "회원 프로필 DynamoDB 테이블 ARN (태스크 역할 IAM 정책 스코프용)"
  type        = string
  default     = ""
}

# 상품 좋아요용 (기본값 빈 문자열 - us-east-1 pilot light는 아직 미지원)
variable "product_likes_table_name" {
  type    = string
  default = ""
}

variable "product_likes_table_arn" {
  type    = string
  default = ""
}

# 상품 리뷰 + 리뷰 사진 + 검열 Lambda용 (기본값 빈 문자열 - us-east-1 pilot light는 아직 미지원)
variable "product_reviews_table_name" {
  type    = string
  default = ""
}

variable "product_reviews_table_arn" {
  type    = string
  default = ""
}

variable "review_photos_bucket_name" {
  type    = string
  default = ""
}

variable "review_photos_bucket_arn" {
  type    = string
  default = ""
}

variable "review_photos_bucket_domain" {
  description = "리뷰 사진 공개 URL 조립용 (https://<domain>/<key>)"
  type        = string
  default     = ""
}

variable "moderation_lambda_arn" {
  type    = string
  default = ""
}

variable "moderation_lambda_name" {
  type    = string
  default = ""
}

# 상품 카탈로그용 (기본값 빈 문자열 - us-east-1 pilot light는 아직 미지원)
variable "product_catalog_table_name" {
  type    = string
  default = ""
}

variable "product_catalog_table_arn" {
  type    = string
  default = ""
}

variable "resource_region" {
  description = "Cognito, DynamoDB, S3, Lambda 데이터 리전. 비어 있으면 ECS 리전을 사용"
  type        = string
  default     = ""
}

variable "product_images_bucket_name" {
  type    = string
  default = ""
}
variable "product_images_bucket_arn" {
  type    = string
  default = ""
}
variable "product_images_bucket_domain" {
  type    = string
  default = ""
}

variable "tavily_api_key_secret_arn" {
  description = "Secrets Manager ARN containing the Tavily API key"
  type        = string
  default     = ""
}

variable "enable_tavily_secret" {
  description = "Whether this regional ECS service reads the Tavily key from Secrets Manager"
  type        = bool
  default     = false
}

variable "review_events_queue_arn" {
  description = "SQS queue used by the asynchronous review pipeline"
  type        = string
  default     = ""
}

variable "review_events_queue_url" {
  description = "SQS queue URL exposed to the backend for future async review publishing"
  type        = string
  default     = ""
}

variable "review_workflow_arn" {
  description = "Step Functions review moderation workflow ARN"
  type        = string
  default     = ""
}

variable "enable_prometheus_collector" {
  description = "Run an ADOT sidecar that scrapes /metrics and writes to Amazon Managed Prometheus"
  type        = bool
  default     = false
}

variable "prometheus_remote_write_endpoint" {
  description = "Amazon Managed Prometheus workspace endpoint used by the ADOT sidecar"
  type        = string
  default     = ""
}
