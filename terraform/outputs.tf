output "api_gateway_endpoint" {
  description = "Node.js 백엔드로 연결되는 API Gateway 호출 URL"
  value       = module.api_gateway.api_endpoint
}

output "static_site_url" {
  description = "S3 정적 웹 호스팅 테스트 URL"
  value       = module.storage.website_endpoint
}

output "us_api_gateway_endpoint" {
  description = "[미국] Node.js 백엔드로 연결되는 API Gateway 호출 URL"
  value       = module.api_gateway_us.api_endpoint
}

output "us_static_site_url" {
  description = "[미국] S3 정적 웹 호스팅 테스트 URL"
  value       = module.storage_us.website_endpoint
}

output "vpc_peering_connection_id" {
  description = "서울 <-> 미국 VPC Peering 연결 ID"
  value       = aws_vpc_peering_connection.seoul_to_us.id
}
