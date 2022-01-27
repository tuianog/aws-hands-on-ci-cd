data "aws_region" "current" {}
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_lambda_function" "project_lambda" {
  filename         = var.lambda_src_path
  function_name    = "${var.project_name}-${var.stage}-lambda"
  role             = aws_iam_role.project_lambda_role.arn
  handler          = var.lambda_handler
  source_code_hash = filebase64sha256(var.lambda_src_path)
  memory_size      = "256"
  timeout          = "60"
  runtime          = "python3.8"
  layers           = [aws_lambda_layer_version.project_lambda_layer.arn]

  environment {
    variables = {
      REGION        = data.aws_region.current.name
      STAGE         = var.stage
      DB_TABLE      = var.database_name
      PRIMARY_KEY   = var.database_primary_key
      SECONDARY_KEY = var.database_secondary_key
    }
  }
}

resource "aws_lambda_layer_version" "project_lambda_layer" {
  filename            = var.lambda_layer_src_path
  layer_name          = "${var.project_name}-${var.stage}-lambda-layer"
  source_code_hash    = filebase64sha256(var.lambda_layer_src_path)
  description         = "Dependencies for project lambda"
  compatible_runtimes = ["python3.7", "python3.8"]
}

resource "aws_iam_role" "project_lambda_role" {
  name        = "${var.project_name}-${var.stage}-lambda-role"
  description = "${var.project_name}-${var.stage}-lambda permissions"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "project_lambda_execution_policy" {
  role       = aws_iam_role.project_lambda_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "project_lambda_dynamo_policy" {
  role       = aws_iam_role.project_lambda_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonDynamoDBFullAccess"
}