variable "project_name" {
  description = "Name of the pipeline project"
}

variable "deploy_project_name" {
  description = "Name of the project for the artifacts folder name used in the build stage"
}

variable "deploy_project_backend_config_file" {
  description = "Path to backend-config file for the deployment project"
}

variable "deploy_project_variables_file" {
  description = "Path to variables file for the deployment project"
}

variable "region" {}

variable "account" {
}

variable "stage" {
}

variable "s3_release_bucket" {}

variable "s3_branch_prefix" {
  description = "S3 prefix key of source branch"
}

variable "branch_name" {
  type        = string
  description = "The name of the branch for the pipeline to listen to"
  default     = "master"
}

variable "terraform_deployer_arn" {}

variable "pipeline_auto_trigger" {
  type        = string
  description = "Flag to set pipeline with auto trigger"
  default     = "false"
}

variable "manual_approval_step" {
  type        = string
  description = "Manual approval step - values allowed: 'true' or 'false'"
  default     = "false"
}