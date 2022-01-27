# Example if needed to deploy from local machine:
# > AWS_PROFILE=... terraform init -reconfigure -backend-config="./variables/backend-config.hcl"
# > AWS_PROFILE=... terraform apply -var-file="./variables/project.tfvars"

# To manually destroy deployed project:
# Run terraform init as described above and then
# > AWS_PROFILE=... terraform destroy -var-file="./variables/project.tfvars"

provider "aws" {
  assume_role {
    role_arn     = var.assume_role_arn
    session_name = "terraform"
  }
  region = "eu-west-1"
}

# S3 backend is set dynamically with backend-config file from terraform init
terraform {
  backend "s3" {}
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}