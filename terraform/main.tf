# ===================== 서울 (ap-northeast-2) =====================

# 1. 네트워크 모듈 호출
module "network" {
  source    = "./modules/network"
  providers = { aws = aws.seoul }

  vpc_cidr        = var.vpc_cidr
  region_name     = var.region_name
  aws_region      = var.aws_region
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

# 2. ALB 모듈 호출 (compute의 의존성 해결, 내부망 전용)
module "alb" {
  source    = "./modules/alb"
  providers = { aws = aws.seoul }

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  region_name        = var.region_name
  container_port     = var.container_port

  # api_gateway 모듈의 VPC Link ENI에서 오는 트래픽만 허용
  vpc_link_security_group_id = module.api_gateway.vpc_link_security_group_id
}

# 3. API Gateway 모듈 호출 (VPC Link로 ALB와 연결)
module "api_gateway" {
  source    = "./modules/api_gateway"
  providers = { aws = aws.seoul }

  region_name        = var.region_name
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  # ALB 모듈에서 출력된 리스너로 프록시
  alb_listener_arn     = module.alb.listener_arn
  cors_allowed_origins = ["https://${var.web_domain}"]
}

# 4. 정적 웹 호스팅용 S3 버킷 (독립적, 다른 모듈과 의존관계 없음)
module "storage" {
  source    = "./modules/storage"
  providers = { aws = aws.seoul }

  region_name                 = var.region_name
  custom_domain               = var.web_domain
  acm_certificate_arn         = aws_acm_certificate_validation.web.certificate_arn
  failover_bucket_domain_name = module.storage_us.bucket_regional_domain_name
  enable_failover_origin      = true
  api_origin_domain_name      = var.api_domain
  api_origin_verify_secret    = random_password.cloudfront_origin.result
}

# 5. 로그인/회원가입 인증 (독립적, 다른 모듈과 의존관계 없음)
module "cognito" {
  source    = "./modules/cognito"
  providers = { aws = aws.seoul }

  region_name          = var.region_name
  site_url             = "https://${var.web_domain}"
  google_client_id     = var.google_client_id
  google_client_secret = var.google_client_secret
}

# 6. 회원 프로필 저장 (독립적, 다른 모듈과 의존관계 없음)
module "dynamodb" {
  source    = "./modules/dynamodb"
  providers = { aws = aws.seoul }

  region_name = var.region_name
}

# 7. 리뷰 사진 검열 Lambda (리뷰 사진 버킷에 의존)
module "lambda_moderation" {
  source    = "./modules/lambda_moderation"
  providers = { aws = aws.seoul }

  region_name                  = var.region_name
  review_photos_bucket_arn     = module.storage.review_photos_bucket_arn
  product_reviews_table_name   = module.dynamodb.product_reviews_table_name
  product_reviews_table_arn    = module.dynamodb.product_reviews_table_arn
  guardrail_profile_identifier = var.bedrock_guardrail_profile_identifier
}

# Review requests are buffered in SQS and delivered to Step Functions by EventBridge Pipes.
module "async_review_pipeline" {
  source    = "./modules/async_review_pipeline"
  providers = { aws = aws.seoul }

  region_name           = var.region_name
  moderation_lambda_arn = module.lambda_moderation.lambda_arn
}

module "monitoring" {
  source    = "./modules/monitoring"
  providers = { aws = aws.seoul }

  region_name = var.region_name
  aws_region  = var.aws_region
  # Keep the workspace independent from the ECS task definition so that the
  # AMP endpoint can be passed back into the task without a dependency cycle.
  ecs_cluster_name       = "${var.region_name}-cluster"
  ecs_service_name       = "${var.region_name}-service"
  moderation_lambda_name = module.lambda_moderation.lambda_name
  review_queue_name      = module.async_review_pipeline.queue_name
  review_dlq_name        = module.async_review_pipeline.dlq_name
  api_gateway_id         = module.api_gateway.api_id
  enable_prometheus      = var.enable_managed_prometheus
  enable_grafana         = var.enable_managed_grafana
}

module "cost_controls" {
  source    = "./modules/cost_controls"
  providers = { aws = aws.us_east_1 }

  region_name              = var.region_name
  enable_cost_controls     = var.enable_cost_controls
  alert_email              = var.cost_alert_email
  monthly_budget_usd       = var.monthly_budget_usd
  anomaly_threshold_usd    = var.cost_anomaly_threshold_usd
  enable_anomaly_detection = var.enable_cost_anomaly_detection
}

resource "aws_secretsmanager_secret" "tavily_api_key" {
  provider                = aws.seoul
  name                    = "${var.region_name}/tavily-api-key"
  description             = "Tavily API key for authenticated backend search"
  recovery_window_in_days = 7
}

# 8. 컴퓨트 모듈 호출
module "compute" {
  source     = "./modules/compute"
  providers  = { aws = aws.seoul }
  depends_on = [aws_secretsmanager_secret_version.cloudfront_origin_seoul]

  # 네트워크 모듈에서 출력된 값 연결
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  # ALB 모듈에서 출력된 값 연결
  alb_security_group_id = module.alb.security_group_id
  target_group_arn      = module.alb.target_group_arn

  # Cognito/DynamoDB 모듈에서 출력된 값 연결 (로그인/회원가입 + 상품 좋아요/리뷰 백엔드용)
  user_pool_id        = module.cognito.user_pool_id
  user_pool_arn       = module.cognito.user_pool_arn
  user_pool_client_id = module.cognito.user_pool_client_id
  dynamodb_table_name = module.dynamodb.table_name
  dynamodb_table_arn  = module.dynamodb.table_arn

  product_likes_table_name = module.dynamodb.product_likes_table_name
  product_likes_table_arn  = module.dynamodb.product_likes_table_arn

  product_reviews_table_name = module.dynamodb.product_reviews_table_name
  product_reviews_table_arn  = module.dynamodb.product_reviews_table_arn

  product_catalog_table_name = module.dynamodb.product_catalog_table_name
  product_catalog_table_arn  = module.dynamodb.product_catalog_table_arn

  review_photos_bucket_name   = module.storage.review_photos_bucket_name
  review_photos_bucket_arn    = module.storage.review_photos_bucket_arn
  review_photos_bucket_domain = module.storage.review_photos_bucket_regional_domain

  product_images_bucket_name   = module.storage.product_images_bucket_name
  product_images_bucket_arn    = module.storage.product_images_bucket_arn
  product_images_bucket_domain = module.storage.product_images_bucket_domain

  moderation_lambda_arn            = module.lambda_moderation.lambda_arn
  moderation_lambda_name           = module.lambda_moderation.lambda_name
  tavily_api_key_secret_arn        = aws_secretsmanager_secret.tavily_api_key.arn
  enable_tavily_secret             = true
  review_events_queue_arn          = module.async_review_pipeline.queue_arn
  review_events_queue_url          = module.async_review_pipeline.queue_url
  review_workflow_arn              = module.async_review_pipeline.state_machine_arn
  origin_verify_secret_arn         = aws_secretsmanager_secret.cloudfront_origin_seoul.arn
  enable_origin_verify_secret      = true
  enable_prometheus_collector      = var.enable_managed_prometheus
  prometheus_remote_write_endpoint = module.monitoring.prometheus_remote_write_endpoint

  # 기타 변수
  region_name    = var.region_name
  aws_region     = var.aws_region
  container_port = var.container_port

  # Architecture baseline: keep two tasks spread across the two private AZs.
  desired_count            = 2
  autoscaling_min_capacity = 2
  autoscaling_max_capacity = 2
}
