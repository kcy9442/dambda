# VPC 생성
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.region_name}-vpc" }
}

locals {
  public_subnets = {
    for index, cidr in var.public_subnets : cidr => {
      cidr = cidr
      az   = "${var.aws_region}${var.availability_zones[index]}"
      name = index + 1
    }
  }
  private_subnets = {
    for index, cidr in var.private_subnets : cidr => {
      cidr = cidr
      az   = "${var.aws_region}${var.availability_zones[index]}"
      name = index + 1
    }
  }
}

# 퍼블릭 서브넷
resource "aws_subnet" "public" {
  for_each                = local.public_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.region_name}-public-subnet-${each.value.name}" }
}

# 프라이빗 서브넷
resource "aws_subnet" "private" {
  for_each          = local.private_subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags              = { Name = "${var.region_name}-private-subnet-${each.value.name}" }
}

# 인터넷 게이트웨이
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.region_name}-igw" }
}

# 퍼블릭 라우팅 테이블
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.region_name}-public-rt" }
}

# 퍼블릭 서브넷 연결
resource "aws_route_table_association" "public" {
  for_each       = local.public_subnets
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway와 EIP (프라이빗 통신용)
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = { Name = "${var.region_name}-nat-eip" }
}

# 개발 환경은 NAT Gateway 하나를 공유해 고정 비용을 줄인다.
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[var.public_subnets[0]].id

  tags = { Name = "${var.region_name}-nat-gw" }
}

# 프라이빗 라우팅 테이블
resource "aws_route_table" "private" {
  for_each = local.private_subnets
  vpc_id   = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  # Cross-region peering routes are managed by standalone aws_route resources.
  # Ignore the combined route set here so this resource does not remove them.
  lifecycle {
    ignore_changes = [route]
  }

  tags = { Name = "${var.region_name}-private-rt-${each.value.name}" }
}

# 프라이빗 서브넷과 라우팅 테이블 연결
resource "aws_route_table_association" "private" {
  for_each       = local.private_subnets
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = values(aws_route_table.private)[*].id # 프라이빗 라우팅 테이블에 S3 경로 추가

  tags = { Name = "${var.region_name}-s3-endpoint" }
}

# DynamoDB Gateway VPC Endpoint
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"

  # 프라이빗 라우팅 테이블에 DynamoDB 경로 추가
  route_table_ids = values(aws_route_table.private)[*].id

  tags = { Name = "${var.region_name}-dynamodb-endpoint" }
}


