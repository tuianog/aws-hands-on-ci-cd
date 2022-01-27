variable "stage" {
}

variable "project_name" {
}

# Needs to be the Chalice variable instantiation
variable "lambda_handler" {
  description = "The handler of the lambda"
  default = "main.app"
}

variable "lambda_src_path" {
  description = "The zip file of the lambda source"
}

variable "lambda_layer_src_path" {
  description = "The zip file of the lambda layer package"
}

variable "database_name" {}
variable "database_primary_key" {}
variable "database_secondary_key" {
  default = ""
}