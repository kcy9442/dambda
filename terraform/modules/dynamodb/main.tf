# 회원 프로필 저장 (닉네임/국가 등). 비밀번호는 저장하지 않음 - Cognito가 자격증명을 전담.
# 조회 패턴이 Cognito sub로 GetItem 하나뿐이라 GSI 불필요, 트래픽도 적어 PAY_PER_REQUEST로 유휴 비용 없앰
resource "aws_dynamodb_table" "user_profiles" {
  name             = "${var.region_name}-user-profiles"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "userId"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "userId"
    type = "S"
  }

  tags = { Name = "${var.region_name}-user-profiles" }

  replica { region_name = "us-east-1" }
}

# 상품 좋아요. "이 유저가 이 상품 좋아요?" GetItem, "이 유저가 좋아요한 전체 상품" Query(userId만) -
# 둘 다 GSI 없이 해결되는 조회 패턴이라 hash+range 키만으로 충분
resource "aws_dynamodb_table" "product_likes" {
  name             = "${var.region_name}-product-likes"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "userId"
  range_key        = "productId"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "userId"
    type = "S"
  }
  attribute {
    name = "productId"
    type = "S"
  }

  tags = { Name = "${var.region_name}-product-likes" }

  replica { region_name = "us-east-1" }
}

# 상품 리뷰(별점+텍스트+선택적 사진). userId를 해시키로 둬서 "유저당 상품 1개 리뷰"를
# PutItem의 ConditionExpression(attribute_not_exists)으로 경합 없이 강제할 수 있게 함.
# 평균 별점은 저장하지 않고 조회 시 GSI 결과에서 계산 (이 규모에서 실시간 집계 카운터는 과함)
resource "aws_dynamodb_table" "product_reviews" {
  name             = "${var.region_name}-product-reviews"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "userId"
  range_key        = "productId"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "userId"
    type = "S"
  }
  attribute {
    name = "productId"
    type = "S"
  }
  attribute {
    name = "createdAt"
    type = "S"
  }

  # "이 상품의 리뷰 최신순 목록" 조회용
  global_secondary_index {
    name            = "product-reviews-by-product"
    hash_key        = "productId"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "moderationExpiresAt"
    enabled        = true
  }

  tags = { Name = "${var.region_name}-product-reviews" }

  replica { region_name = "us-east-1" }
}

# 상품 카탈로그 (이름/가격/판매처/추천이유/사진). 조회는 항상 "전체 목록" 하나뿐이고
# 카테고리 필터는 클라이언트에서 하므로 GSI 없이 hash key(itemId)만으로 충분
resource "aws_dynamodb_table" "product_catalog" {
  name             = "${var.region_name}-product-catalog"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "itemId"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "itemId"
    type = "S"
  }

  tags = { Name = "${var.region_name}-product-catalog" }

  replica { region_name = "us-east-1" }
}
