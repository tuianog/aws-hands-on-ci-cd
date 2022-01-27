resource "aws_kms_key" "release_bucket_kms_key" {
  description             = "This key is used to encrypt bucket objects on release bucket"
}

# Release bucket
# Needs to have versioning enabled
resource "aws_s3_bucket" "release_bucket" {
  bucket        = "${local.project_name}-release-bucket"
  force_destroy = true
  acl           = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.release_bucket_kms_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}