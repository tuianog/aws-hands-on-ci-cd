resource "aws_s3_bucket" "project_bucket" {
  bucket        = "${var.project_name}-${var.stage}-bucket"
  force_destroy = true
  acl           = "private"
}