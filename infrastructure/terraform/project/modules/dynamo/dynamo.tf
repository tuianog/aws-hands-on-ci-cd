locals {
  main_key = "id"
  secondary_key = "sort_id"
}

resource "aws_dynamodb_table" "dynamo" {
  name             = "${var.project_name}-${var.stage}-db"
  billing_mode     = "PROVISIONED"
  read_capacity    = 5
  write_capacity   = 5
  hash_key         = local.main_key
  range_key        = local.secondary_key

  attribute {
    name =  local.main_key
    type = "S"
  }

  attribute {
    name =  local.secondary_key
    type = "S"
  }

  global_secondary_index {
    name               = local.secondary_key
    hash_key           = local.secondary_key
    read_capacity    = 5
    write_capacity   = 5
    projection_type    = "INCLUDE"
    non_key_attributes = [local.main_key]
  }
}