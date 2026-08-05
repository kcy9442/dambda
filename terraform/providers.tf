# 서울 단일 리전 배포

provider "aws" {
  alias  = "seoul"
  region = var.aws_region
}

provider "aws" {
  alias  = "us_east_1"
  region = var.us_aws_region
}

