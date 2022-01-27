resource "aws_s3_bucket" "artifact_bucket" {
  bucket        = "${var.project_name}-${var.stage}-pipeline-artifact-bucket"
  force_destroy = true
  acl           = "private"
}