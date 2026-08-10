# Preserve deployed identities while count indexes become stable CIDR keys.

moved {
  from = module.network.aws_subnet.public[0]
  to   = module.network.aws_subnet.public["10.0.1.0/24"]
}
moved {
  from = module.network.aws_subnet.public[1]
  to   = module.network.aws_subnet.public["10.0.2.0/24"]
}
moved {
  from = module.network.aws_subnet.private[0]
  to   = module.network.aws_subnet.private["10.0.10.0/24"]
}
moved {
  from = module.network.aws_subnet.private[1]
  to   = module.network.aws_subnet.private["10.0.11.0/24"]
}
moved {
  from = module.network.aws_route_table_association.public[0]
  to   = module.network.aws_route_table_association.public["10.0.1.0/24"]
}
moved {
  from = module.network.aws_route_table_association.public[1]
  to   = module.network.aws_route_table_association.public["10.0.2.0/24"]
}
moved {
  from = module.network.aws_route_table.private[0]
  to   = module.network.aws_route_table.private["10.0.10.0/24"]
}
moved {
  from = module.network.aws_route_table.private[1]
  to   = module.network.aws_route_table.private["10.0.11.0/24"]
}
moved {
  from = module.network.aws_route_table_association.private[0]
  to   = module.network.aws_route_table_association.private["10.0.10.0/24"]
}
moved {
  from = module.network.aws_route_table_association.private[1]
  to   = module.network.aws_route_table_association.private["10.0.11.0/24"]
}

moved {
  from = module.network_us.aws_subnet.public[0]
  to   = module.network_us.aws_subnet.public["10.1.1.0/24"]
}
moved {
  from = module.network_us.aws_subnet.public[1]
  to   = module.network_us.aws_subnet.public["10.1.2.0/24"]
}
moved {
  from = module.network_us.aws_subnet.private[0]
  to   = module.network_us.aws_subnet.private["10.1.10.0/24"]
}
moved {
  from = module.network_us.aws_subnet.private[1]
  to   = module.network_us.aws_subnet.private["10.1.11.0/24"]
}
moved {
  from = module.network_us.aws_route_table_association.public[0]
  to   = module.network_us.aws_route_table_association.public["10.1.1.0/24"]
}
moved {
  from = module.network_us.aws_route_table_association.public[1]
  to   = module.network_us.aws_route_table_association.public["10.1.2.0/24"]
}
moved {
  from = module.network_us.aws_route_table.private[0]
  to   = module.network_us.aws_route_table.private["10.1.10.0/24"]
}
moved {
  from = module.network_us.aws_route_table.private[1]
  to   = module.network_us.aws_route_table.private["10.1.11.0/24"]
}
moved {
  from = module.network_us.aws_route_table_association.private[0]
  to   = module.network_us.aws_route_table_association.private["10.1.10.0/24"]
}
moved {
  from = module.network_us.aws_route_table_association.private[1]
  to   = module.network_us.aws_route_table_association.private["10.1.11.0/24"]
}

moved {
  from = aws_route.seoul_to_us[0]
  to   = aws_route.seoul_to_us["10.0.10.0/24"]
}
moved {
  from = aws_route.seoul_to_us[1]
  to   = aws_route.seoul_to_us["10.0.11.0/24"]
}
moved {
  from = aws_route.us_to_seoul[0]
  to   = aws_route.us_to_seoul["10.1.10.0/24"]
}
moved {
  from = aws_route.us_to_seoul[1]
  to   = aws_route.us_to_seoul["10.1.11.0/24"]
}
