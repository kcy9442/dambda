# 서울 단일 리전 배포

provider "aws" {
  alias  = "seoul"
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = var.us_aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = "DAMBDA"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "dambda"
    CostCenter  = "DAMBDA"
  }
}


