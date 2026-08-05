# terraform.tfvars
aws_region      = "ap-northeast-2"
region_name     = "my-app-dev"
vpc_cidr        = "10.0.0.0/16"
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]
container_port  = 80

# 미국(us-east-1) pilot-light 재해복구 리전
us_aws_region      = "us-east-1"
us_region_name     = "my-app-dev-us"
us_vpc_cidr        = "10.1.0.0/16"
us_public_subnets  = ["10.1.1.0/24", "10.1.2.0/24"]
us_private_subnets = ["10.1.10.0/24", "10.1.11.0/24"]
