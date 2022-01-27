data "aws_region" "current" {}
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

variable "project_name" {
}

variable "region" {}

variable "account" {
}

variable "stage" {
}

variable "release_bucket" {
}

variable "release_bucket_kms_key_id" {
}

variable "release_bucket_kms_key_arn" {
}

variable "lambda_src_path" {
}

variable "lambda_handler" {
  type    = string
  default = "main.app"
}

variable "lambda_dependencies_path" {}

variable "secret_name" {
  description = "The secret name of Secrets Manager"
}