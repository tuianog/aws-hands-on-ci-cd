output "backend_lambda_name" {
  value = aws_lambda_function.project_lambda.function_name
}

output "backend_lambda_arn" {
  value = aws_lambda_function.project_lambda.arn
}