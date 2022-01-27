# Example: AWS_PROFILE=... terraform plan
# Build artifacts before running terraform plan/apply
provider "aws" {
  region  = "eu-west-1"
}

# Bucket needs to exist before terraform init
# Enable bucket versioning
terraform {
  backend "s3" {
    region         = "eu-west-1"
    bucket         = "terraform-state-ACCOUNT-eu-west-1"
    dynamodb_table = "terraform-state-ACCOUNT-eu-west-1"
    key            = "aws-hands-on-ci-cd/pipeline/terraform.tfstate"
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}