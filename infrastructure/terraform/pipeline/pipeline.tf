locals {
  # For the infrastructure
  project_name                  = "aws-hands-on-ci-cd"
  deploy_project_variables_path = "${path.root}/../project/variables"

  region = data.aws_region.current.name
  account = data.aws_caller_identity.current.account_id

  # Webhook
  webhook_lambda_src_path              = "/tmp/${local.project_name}/build/webhook/deployment.zip"
  webhook_lambda_dependencies_path     = "/tmp/${local.project_name}/build/webhook/dependencies.zip"
  # From Secrets Manager
  secret_name                          = "test_webhook"
}

# Create a pipeline per environment
module "pipeline_test" {
  source                             = "./modules/codepipeline"
  region                             = local.region
  account                            = local.account
  project_name                       = local.project_name
  stage                              = "test"
  s3_branch_prefix                   = local.project_name
  branch_name                        = "master"
  s3_release_bucket                  = aws_s3_bucket.release_bucket.bucket
  terraform_deployer_arn             = aws_iam_role.terraform-deployer-role.arn
  pipeline_auto_trigger              = "true"
  manual_approval_step               = "false"
  deploy_project_name                = "aws-hands-on-ci-cd-project"
  deploy_project_backend_config_file = "${local.deploy_project_variables_path}/backend-config.hcl"
  deploy_project_variables_file      = "${local.deploy_project_variables_path}/project.tfvars"
}

# Webhook per account
module "webhook" {
  source                       = "./modules/webhook"
  stage                        = "webhook"
  region                       = local.region
  account                      = local.account
  project_name                 = local.project_name
  release_bucket               = aws_s3_bucket.release_bucket.bucket
  release_bucket_kms_key_id    = aws_kms_key.release_bucket_kms_key.id
  release_bucket_kms_key_arn   = aws_kms_key.release_bucket_kms_key.arn
  lambda_src_path              = local.webhook_lambda_src_path
  lambda_dependencies_path     = local.webhook_lambda_dependencies_path
  secret_name                  = local.secret_name
}