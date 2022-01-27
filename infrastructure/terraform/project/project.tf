locals {
  artifacts_dir = "/tmp/${var.project_name}/build/"
  lambda_src_zip_location = "${local.artifacts_dir}/deployment.zip"
  lambda_dependencies_zip_location = "${local.artifacts_dir}/dependencies.zip"
}

module "s3" {
  source = "./modules/s3"
  project_name                       = var.project_name
  stage                              = var.stage
  region                             = data.aws_region.current.name
}

module "api-gateway" {
  source = "./modules/api-gateway"
  project_name                       = var.project_name
  stage                              = var.stage
  backend_lambda_arn                 = module.lambda.backend_lambda_arn
  backend_lambda_name                = module.lambda.backend_lambda_name
}

module "dynamo" {
  source = "./modules/dynamo"
  project_name                       = var.project_name
  stage                              = var.stage
}

module "lambda" {
  source = "./modules/lambda"
  project_name                       = var.project_name
  stage                              = var.stage
  lambda_src_path                    = local.lambda_src_zip_location
  lambda_layer_src_path              = local.lambda_dependencies_zip_location
  database_name                      = module.dynamo.dynamo_table_name
  database_primary_key               = module.dynamo.dynamo_table_primary_key
  database_secondary_key             = module.dynamo.dynamo_table_secondary_key
}