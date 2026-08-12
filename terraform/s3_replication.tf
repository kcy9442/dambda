locals {
  s3_replication_pairs = {
    static_site = {
      source_bucket      = module.storage.bucket_name
      source_bucket_arn  = module.storage.bucket_arn
      destination_bucket = module.storage_us.bucket_name
      destination_arn    = module.storage_us.bucket_arn
    }
    review_photos = {
      source_bucket      = module.storage.review_photos_bucket_name
      source_bucket_arn  = module.storage.review_photos_bucket_arn
      destination_bucket = module.storage_us.review_photos_bucket_name
      destination_arn    = module.storage_us.review_photos_bucket_arn
    }
    product_images = {
      source_bucket      = module.storage.product_images_bucket_name
      source_bucket_arn  = module.storage.product_images_bucket_arn
      destination_bucket = module.storage_us.product_images_bucket_name
      destination_arn    = module.storage_us.product_images_bucket_arn
    }
  }
}

resource "aws_s3_bucket_versioning" "seoul" {
  provider = aws.seoul
  for_each = local.s3_replication_pairs
  bucket   = each.value.source_bucket
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_versioning" "us" {
  provider = aws.us_east_1
  for_each = local.s3_replication_pairs
  bucket   = each.value.destination_bucket
  versioning_configuration { status = "Enabled" }
}

resource "aws_iam_role" "s3_replication" {
  provider = aws.seoul
  name     = "${var.region_name}-s3-cross-region-replication"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "sts:AssumeRole", Principal = { Service = "s3.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "s3_replication" {
  provider = aws.seoul
  name     = "${var.region_name}-s3-cross-region-replication"
  role     = aws_iam_role.s3_replication.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
        Resource = [for pair in values(local.s3_replication_pairs) : pair.source_bucket_arn]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"]
        Resource = [for pair in values(local.s3_replication_pairs) : "${pair.source_bucket_arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"]
        Resource = [for pair in values(local.s3_replication_pairs) : "${pair.destination_arn}/*"]
      }
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "seoul_to_us" {
  provider = aws.seoul
  for_each = local.s3_replication_pairs
  bucket   = each.value.source_bucket
  role     = aws_iam_role.s3_replication.arn

  rule {
    id     = "replicate-all-to-${var.us_aws_region}"
    status = "Enabled"
    filter {}
    destination {
      bucket        = each.value.destination_arn
      storage_class = "STANDARD"
    }
    delete_marker_replication { status = "Enabled" }
  }

  depends_on = [
    aws_s3_bucket_versioning.seoul,
    aws_s3_bucket_versioning.us,
    aws_iam_role_policy.s3_replication,
  ]
}
