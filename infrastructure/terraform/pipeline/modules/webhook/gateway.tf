locals {
  api_title = "${var.project_name}-webhook-api"
  swagger_template = templatefile(format("%s/webhook.yml", path.module), {
    title       = local.api_title
    description = "Webhook API"
    region      = data.aws_region.current.name
    lambda_arn  = aws_lambda_function.webhook_lambda.arn
  })
}

resource "aws_api_gateway_rest_api" "api-gw" {
  name        = local.api_title
  description = "Webhook API"
  body        = local.swagger_template
}

resource "aws_api_gateway_deployment" "api-gw-deployment" {
  rest_api_id = aws_api_gateway_rest_api.api-gw.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api-gw-stage" {
  stage_name    = var.stage
  rest_api_id   = aws_api_gateway_rest_api.api-gw.id
  deployment_id = aws_api_gateway_deployment.api-gw-deployment.id
}

resource "aws_lambda_permission" "allow-invoke-api" {
  statement_id  = "AllowExecutionOfCoreApiFromAPIGW"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.webhook_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api-gw.execution_arn}/*/*/*"
}