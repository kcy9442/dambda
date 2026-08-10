# 미국(us-east-1) pilot-light 재해복구 스택.
# 평상시 ECS desired_count는 0이며, 전환 시 값을 1 이상으로 올린다.

module "network_us" {
  source    = "./modules/network"
  providers = { aws = aws.us_east_1 }

  vpc_cidr        = var.us_vpc_cidr
  region_name     = var.us_region_name
  aws_region      = var.us_aws_region
  public_subnets  = var.us_public_subnets
  private_subnets = var.us_private_subnets
}

module "alb_us" {
  source    = "./modules/alb"
  providers = { aws = aws.us_east_1 }

  vpc_id                     = module.network_us.vpc_id
  private_subnet_ids         = module.network_us.private_subnet_ids
  region_name                = var.us_region_name
  container_port             = var.container_port
  vpc_link_security_group_id = module.api_gateway_us.vpc_link_security_group_id
}

module "api_gateway_us" {
  source    = "./modules/api_gateway"
  providers = { aws = aws.us_east_1 }

  region_name        = var.us_region_name
  vpc_id             = module.network_us.vpc_id
  private_subnet_ids = module.network_us.private_subnet_ids
  alb_listener_arn   = module.alb_us.listener_arn
}

module "storage_us" {
  source    = "./modules/storage"
  providers = { aws = aws.us_east_1 }

  region_name = var.us_region_name
}

module "compute_us" {
  source    = "./modules/compute"
  providers = { aws = aws.us_east_1 }

  vpc_id                = module.network_us.vpc_id
  private_subnet_ids    = module.network_us.private_subnet_ids
  alb_security_group_id = module.alb_us.security_group_id
  target_group_arn      = module.alb_us.target_group_arn
  region_name           = var.us_region_name
  aws_region            = var.us_aws_region
  resource_region       = var.aws_region
  container_port        = var.container_port

  # 기존 사용자와 관리자 권한을 유지하기 위해 서울 Cognito를 공유한다.
  user_pool_id        = module.cognito.user_pool_id
  user_pool_arn       = module.cognito.user_pool_arn
  user_pool_client_id = module.cognito.user_pool_client_id

  # 상품, 리뷰, 좋아요 및 프로필 데이터도 현재 서울 테이블을 공유한다.
  dynamodb_table_name        = module.dynamodb.table_name
  dynamodb_table_arn         = module.dynamodb.table_arn
  product_likes_table_name   = module.dynamodb.product_likes_table_name
  product_likes_table_arn    = module.dynamodb.product_likes_table_arn
  product_reviews_table_name = module.dynamodb.product_reviews_table_name
  product_reviews_table_arn  = module.dynamodb.product_reviews_table_arn
  product_catalog_table_name = module.dynamodb.product_catalog_table_name
  product_catalog_table_arn  = module.dynamodb.product_catalog_table_arn

  # 관리자 상품 이미지와 리뷰 사진도 기존 객체를 그대로 사용한다.
  review_photos_bucket_name    = module.storage.review_photos_bucket_name
  review_photos_bucket_arn     = module.storage.review_photos_bucket_arn
  review_photos_bucket_domain  = module.storage.review_photos_bucket_regional_domain
  product_images_bucket_name   = module.storage.product_images_bucket_name
  product_images_bucket_arn    = module.storage.product_images_bucket_arn
  product_images_bucket_domain = module.storage.product_images_bucket_domain

  moderation_lambda_arn  = module.lambda_moderation.lambda_arn
  moderation_lambda_name = module.lambda_moderation.lambda_name

  desired_count            = 0
  autoscaling_min_capacity = 0
  autoscaling_max_capacity = 5
}
