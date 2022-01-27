# Example: AWS_PROFILE=... terraform plan
# IMPORTANT: only run this module when adding a new secret
# Do not commit the actual secret value
provider "aws" {
  region  = "eu-west-1"
}

terraform {
  backend "s3" {
    region         = "eu-west-1"
    bucket         = "terraform-state-ACCOUNT-eu-west-1"
    dynamodb_table = "terraform-state-ACCOUNT-eu-west-1"
    key            = "aws-hands-on-ci-cd/secret/terraform.tfstate"
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}