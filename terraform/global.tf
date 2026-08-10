# 서울에서 미국으로 VPC Peering을 요청하고 미국 provider에서 수락한다.
resource "aws_vpc_peering_connection" "seoul_to_us" {
  provider = aws.seoul

  vpc_id      = module.network.vpc_id
  peer_vpc_id = module.network_us.vpc_id
  peer_region = var.us_aws_region

  tags = { Name = "${var.region_name}-to-${var.us_region_name}-peering" }
}

resource "aws_vpc_peering_connection_accepter" "us_accept" {
  provider = aws.us_east_1

  vpc_peering_connection_id = aws_vpc_peering_connection.seoul_to_us.id
  auto_accept               = true

  tags = { Name = "${var.us_region_name}-accept-peering" }
}

resource "aws_route" "seoul_to_us" {
  provider = aws.seoul
  count    = length(module.network.private_route_table_ids)

  route_table_id            = module.network.private_route_table_ids[count.index]
  destination_cidr_block    = var.us_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.seoul_to_us.id
}

resource "aws_route" "us_to_seoul" {
  provider = aws.us_east_1
  count    = length(module.network_us.private_route_table_ids)

  route_table_id            = module.network_us.private_route_table_ids[count.index]
  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.seoul_to_us.id

  depends_on = [aws_vpc_peering_connection_accepter.us_accept]
}
