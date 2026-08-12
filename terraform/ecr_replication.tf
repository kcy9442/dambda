data "aws_caller_identity" "current" {}

resource "aws_ecr_replication_configuration" "backend" {
  provider = aws.seoul

  replication_configuration {
    rule {
      destination {
        region      = var.us_aws_region
        registry_id = data.aws_caller_identity.current.account_id
      }
      repository_filter {
        filter      = "${var.region_name}-backend"
        filter_type = "PREFIX_MATCH"
      }
    }
  }
}
