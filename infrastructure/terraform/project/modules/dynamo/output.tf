output "dynamo_table_id" {
  value = aws_dynamodb_table.dynamo.id
}

output "dynamo_table_name" {
  value = aws_dynamodb_table.dynamo.name
}

output "dynamo_table_primary_key" {
  value = local.main_key
}

output "dynamo_table_secondary_key" {
  value = local.secondary_key
}