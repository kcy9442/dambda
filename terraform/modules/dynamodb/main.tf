# 회원 프로필 저장 (닉네임/국가 등). 비밀번호는 저장하지 않음 - Cognito가 자격증명을 전담.
# 조회 패턴이 Cognito sub로 GetItem 하나뿐이라 GSI 불필요, 트래픽도 적어 PAY_PER_REQUEST로 유휴 비용 없앰
resource "aws_dynamodb_table" "user_profiles" {
  name         = "${var.region_name}-user-profiles"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  tags = { Name = "${var.region_name}-user-profiles" }
}
