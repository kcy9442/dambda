# VPC ID 노출
output "vpc_id" {
  description = "생성된 VPC의 ID"
  value       = aws_vpc.main.id
}

# 퍼블릭 서브넷 ID 리스트 노출
output "public_subnet_ids" {
  description = "퍼블릭 서브넷들의 ID 리스트"
  value       = [for cidr in var.public_subnets : aws_subnet.public[cidr].id]
}

# 프라이빗 서브넷 ID 리스트 노출
output "private_subnet_ids" {
  description = "프라이빗 서브넷들의 ID 리스트"
  value       = [for cidr in var.private_subnets : aws_subnet.private[cidr].id]
}

# 프라이빗 라우팅 테이블 ID 리스트 (NAT 게이트웨이와 매칭용)
output "private_route_table_ids" {
  description = "프라이빗 라우팅 테이블 ID 리스트"
  value       = [for cidr in var.private_subnets : aws_route_table.private[cidr].id]
}

# VPC CIDR (피어링 할 때 상대방 CIDR 알기 위해 필요)
output "vpc_cidr" {
  description = "VPC의 CIDR 블록"
  value       = aws_vpc.main.cidr_block
}


