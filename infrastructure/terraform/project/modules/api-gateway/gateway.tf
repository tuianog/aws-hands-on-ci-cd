data "aws_region" "current" {}

locals {
  api_title = "${var.project_name}-${var.stage}-api"
  swagger_template = templatefile(format("%s/gateway.yml", path.module), {
    title       = local.api_title
    description = "Test API"
    region      = data.aws_region.current.name
    lambda_arn  = var.backend_lambda_arn
    api_key     = aws_api_gateway_api_key.api-gw-key.value
  })
}

resource "aws_api_gateway_rest_api" "api-gw" {
  name        = local.api_title
  description = "${var.project_name}-${var.stage} API"
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
  function_name = var.backend_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api-gw.execution_arn}/*/*/*"
}

# API key
resource "aws_api_gateway_usage_plan" "api-gw-usage-plan" {
  name = "${var.project_name}-${var.stage}-api-gw-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.api-gw.id
    stage  = aws_api_gateway_stage.api-gw-stage.stage_name
  }
}

# Auto generated
resource "aws_api_gateway_api_key" "api-gw-key" {
  name = "${var.project_name}-${var.stage}-api-gw-key"
}

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.api-gw-key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.api-gw-usage-plan.id
}