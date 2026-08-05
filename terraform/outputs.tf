output "api_gateway_endpoint" {
  description = "Node.js 백엔드로 연결되는 API Gateway 호출 URL"
  value       = module.api_gateway.api_endpoint
}

output "static_site_url" {
  description = "CloudFront HTTPS Flutter Web URL"
  value       = module.storage.website_endpoint
}

output "backend_ecr_repository_url" {
  description = "서울 리전 백엔드 Docker 이미지를 push할 ECR 저장소 URL"
  value       = module.compute.ecr_repository_url
}

output "backend_ecs_cluster_name" {
  description = "서울 리전 백엔드 ECS 클러스터 이름"
  value       = module.compute.cluster_name
}

output "backend_ecs_service_name" {
  description = "서울 리전 백엔드 ECS 서비스 이름"
  value       = module.compute.service_name
}

output "cognito_oauth_domain" {
  value = module.cognito.oauth_domain
}

output "social_provider_callback_url" {
  value = module.cognito.social_provider_callback_url
}

output "us_api_gateway_endpoint" {
  description = "미국 재해복구 API Gateway URL"
  value       = module.api_gateway_us.api_endpoint
}

output "us_static_site_url" {
  description = "미국 재해복구 CloudFront URL"
  value       = module.storage_us.website_endpoint
}

output "us_backend_ecr_repository_url" {
  description = "미국 재해복구 백엔드 ECR URL"
  value       = module.compute_us.ecr_repository_url
}

output "vpc_peering_connection_id" {
  description = "서울과 미국 VPC Peering 연결 ID"
  value       = aws_vpc_peering_connection.seoul_to_us.id
}
