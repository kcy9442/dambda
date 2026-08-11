# 로그 보관을 위한 CloudWatch 로그 그룹
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.region_name}-logs"
  retention_in_days = 30
}

# ECS 서비스를 담을 클러스터
resource "aws_ecs_cluster" "main" {
  name = "${var.region_name}-cluster"
}

# 컨테이너 접근 제어 보안 그룹 (ALB 트래픽 허용)
resource "aws_security_group" "ecs_sg" {
  name   = "${var.region_name}-ecs-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS 에이전트 실행 역할
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.region_name}-ecs-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_execution_secrets" {
  count = var.enable_tavily_secret ? 1 : 0
  name  = "${var.region_name}-ecs-tavily-secret"
  role  = aws_iam_role.ecs_task_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["secretsmanager:GetSecretValue"]
      Effect   = "Allow"
      Resource = var.tavily_api_key_secret_arn
    }]
  })
}

# 앱 태스크 역할 (Lambda 호출 및 추후 AMP 권한 확보)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.region_name}-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# dynamodb_table_arn/user_pool_arn이 빈 문자열이면(us-east-1 pilot light) 해당 statement를
# 아예 빼야 함 - IAM 정책에 Resource = "" 를 넣으면 apply 시점에 거부당함
locals {
  dynamodb_statements = var.dynamodb_table_arn != "" ? [
    {
      Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem"]
      Effect   = "Allow"
      Resource = var.dynamodb_table_arn
    }
  ] : []

  cognito_statements = var.user_pool_arn != "" ? [
    {
      # 회원가입/로그인/내 정보 조회에 쓰는 Admin* API. GetUser도 액세스 토큰이 아니라
      # 태스크 역할의 IAM 자격증명으로 SigV4 서명되므로 이 정책이 있어야 통과함
      Action = [
        "cognito-idp:AdminCreateUser",
        "cognito-idp:AdminSetUserPassword",
        "cognito-idp:AdminDeleteUser",
        "cognito-idp:AdminInitiateAuth",
        "cognito-idp:AdminGetUser",
        "cognito-idp:GetUser",
        "cognito-idp:AdminListGroupsForUser",
      ]
      Effect   = "Allow"
      Resource = var.user_pool_arn
    }
  ] : []

  product_likes_statements = var.product_likes_table_arn != "" ? [
    {
      Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:Query"]
      Effect   = "Allow"
      Resource = var.product_likes_table_arn
    }
  ] : []

  product_reviews_statements = var.product_reviews_table_arn != "" ? [
    {
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan",
      ]
      Effect = "Allow"
      # 목록은 강한 일관성의 base table Scan, 인덱스는 호환용 Query에 사용한다.
      Resource = [var.product_reviews_table_arn, "${var.product_reviews_table_arn}/index/*"]
    }
  ] : []

  review_photos_statements = var.review_photos_bucket_arn != "" ? [
    {
      Action   = ["s3:PutObject", "s3:DeleteObject"]
      Effect   = "Allow"
      Resource = "${var.review_photos_bucket_arn}/*"
    }
  ] : []

  # 검열 Lambda 호출 권한. 원래 lambda:InvokeFunction이 Resource="*"인 플레이스홀더로 남아있었는데
  # (아직 실제 소비자가 없어서), 이번에 처음으로 실사용처가 생겨서 이 특정 Lambda ARN으로 좁힘
  moderation_lambda_statements = var.moderation_lambda_arn != "" ? [
    {
      Action   = ["lambda:InvokeFunction"]
      Effect   = "Allow"
      Resource = var.moderation_lambda_arn
    }
  ] : []

  # 상품 카탈로그는 백엔드가 읽기만 함 - 쓰기(시딩)는 개발자가 seed 스크립트를
  # 직접 자기 자격증명으로 실행하므로 태스크 역할에는 Put/Delete를 주지 않음
  product_catalog_statements = var.product_catalog_table_arn != "" ? [
    {
      Action   = ["dynamodb:GetItem", "dynamodb:Scan", "dynamodb:PutItem", "dynamodb:DeleteItem"]
      Effect   = "Allow"
      Resource = var.product_catalog_table_arn
    }
  ] : []

  product_images_statements = var.product_images_bucket_arn != "" ? [{
    Action   = ["s3:PutObject", "s3:DeleteObject"]
    Effect   = "Allow"
    Resource = "${var.product_images_bucket_arn}/*"
  }] : []

  async_review_statements = var.review_events_queue_arn != "" && var.review_workflow_arn != "" ? [
    {
      Action   = ["sqs:SendMessage"]
      Effect   = "Allow"
      Resource = var.review_events_queue_arn
    },
    {
      Action   = ["states:StartExecution"]
      Effect   = "Allow"
      Resource = var.review_workflow_arn
    }
  ] : []
}

# AMP + 로그인·회원가입/좋아요/리뷰 백엔드가 쓰는 DynamoDB/Cognito/S3/Lambda 권한
resource "aws_iam_policy" "ecs_task_policy" {
  name = "${var.region_name}-ecs-task-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Action   = ["aps:RemoteWrite"]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          # Translate는 리소스 단위 권한 스코핑을 지원 안 해서 항상 "*".
          # SourceLanguageCode: 'auto'를 쓰면 내부적으로 comprehend:DetectDominantLanguage도
          # 호출하므로 그 권한도 같이 필요함 (없으면 AccessDeniedException)
          Action   = ["translate:TranslateText", "comprehend:DetectDominantLanguage"]
          Effect   = "Allow"
          Resource = "*"
        },
      ],
      local.dynamodb_statements,
      local.cognito_statements,
      local.product_likes_statements,
      local.product_reviews_statements,
      local.review_photos_statements,
      local.moderation_lambda_statements,
      local.product_catalog_statements,
      local.product_images_statements,
      local.async_review_statements,
    )
  })
}

resource "aws_iam_role_policy_attachment" "task_permissions" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

# 백엔드 컨테이너 이미지 저장소 (로그인/회원가입 Express 앱)
resource "aws_ecr_repository" "backend" {
  name                 = "${var.region_name}-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "최근 10개 이미지만 보관"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

# ECS 작업 정의 (로그인/회원가입 Express 백엔드)
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.region_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "app"
      image = "${aws_ecr_repository.backend.repository_url}:latest"
      portMappings = [{
        containerPort = var.container_port
        hostPort      = var.container_port
      }]
      # 시크릿 없음 - Cognito가 자격증명을 전담하므로 클라이언트 시크릿/DB 비밀번호가 없음
      environment = [
        { name = "PORT", value = tostring(var.container_port) },
        { name = "AWS_REGION", value = var.aws_region },
        { name = "RESOURCE_REGION", value = var.resource_region != "" ? var.resource_region : var.aws_region },
        { name = "USER_POOL_ID", value = var.user_pool_id },
        { name = "USER_POOL_CLIENT_ID", value = var.user_pool_client_id },
        { name = "DYNAMODB_TABLE_NAME", value = var.dynamodb_table_name },
        { name = "PRODUCT_LIKES_TABLE_NAME", value = var.product_likes_table_name },
        { name = "PRODUCT_REVIEWS_TABLE_NAME", value = var.product_reviews_table_name },
        { name = "S3_REVIEW_PHOTOS_BUCKET", value = var.review_photos_bucket_name },
        { name = "S3_REVIEW_PHOTOS_DOMAIN", value = var.review_photos_bucket_domain },
        { name = "MODERATION_LAMBDA_NAME", value = var.moderation_lambda_name },
        { name = "PRODUCT_CATALOG_TABLE_NAME", value = var.product_catalog_table_name },
        { name = "S3_PRODUCT_IMAGES_BUCKET", value = var.product_images_bucket_name },
        { name = "S3_PRODUCT_IMAGES_DOMAIN", value = var.product_images_bucket_domain },
        { name = "REVIEW_EVENTS_QUEUE_URL", value = var.review_events_queue_url },
        { name = "REVIEW_WORKFLOW_ARN", value = var.review_workflow_arn },
      ]
      secrets = var.enable_tavily_secret ? [
        { name = "TAVILY_API_KEY", valueFrom = var.tavily_api_key_secret_arn }
      ] : []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "app"
        }
      }
    }
  ])
}

# ECS 서비스
resource "aws_ecs_service" "main" {
  name            = "${var.region_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "app"
    container_port   = var.container_port
  }
}

# 오토 스케일링 대상
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# CPU 기반 오토 스케일링 정책
resource "aws_appautoscaling_policy" "ecs_policy" {
  name               = "${var.region_name}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 60.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
