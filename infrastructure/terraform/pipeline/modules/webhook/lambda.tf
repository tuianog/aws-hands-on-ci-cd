data "aws_vpc" "private_vpc" {
  tags = {
    Name = "private"
  }
}

data "aws_subnet_ids" "private_vpc_subnet_ids" {
  vpc_id = data.aws_vpc.private_vpc.id
}

resource "aws_security_group" "webhook_lambda_sec_group" {
  name        = "${var.project_name}-webhook-lambda"
  description = "Security group for webhook lambda"
  vpc_id      = data.aws_vpc.private_vpc.id

  egress {
    description      = "Allow full outgoing traffic"
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

locals {
  # https://github.com/lambci/git-lambda-layer
  git_executable_lambda_layer_arn = "arn:aws:lambda:${var.region}:553035198032:layer:git-lambda2:7"
}

data "local_file" "known_hosts_file" {
  filename = "${path.module}/known_hosts"
}

resource "aws_lambda_function" "webhook_lambda" {
  filename         = var.lambda_src_path
  description      = "Webhook lambda"
  function_name    = "${var.project_name}-webhook"
  role             = aws_iam_role.webhook_lambda_role.arn
  handler          = var.lambda_handler
  source_code_hash = filebase64sha256(var.lambda_src_path)
  memory_size      = "512"
  timeout          = 5 * 60
  runtime          = "python3.8"
  layers           = [aws_lambda_layer_version.webhook_lambda_layer.arn, local.git_executable_lambda_layer_arn]

  vpc_config {
    subnet_ids         = data.aws_subnet_ids.private_vpc_subnet_ids.ids
    security_group_ids = [aws_security_group.webhook_lambda_sec_group.id]
  }

  environment {
    variables = {
      RELEASE_BUCKET                   = var.release_bucket
      RELEASE_BUCKET_KMS_KEY_ID        = var.release_bucket_kms_key_id
      SECRET_NAME                      = var.secret_name
      KNOWN_HOSTS_B64                  = data.local_file.known_hosts_file.content_base64
    }
  }
}

resource "aws_lambda_layer_version" "webhook_lambda_layer" {
  filename            = var.lambda_dependencies_path
  layer_name          = "${var.project_name}-webhook-layer"
  source_code_hash    = filebase64sha256(var.lambda_dependencies_path)
  description         = "Dependencies for webhook lambda"
  compatible_runtimes = ["python3.7", "python3.8"]
}

resource "aws_iam_role" "webhook_lambda_role" {
  name        = "${var.project_name}-webhook-lambda-role"
  description = "${var.project_name}-webhook Lambda permissions"

  assume_role_policy = data.aws_iam_policy_document.webhook_lambda_role_policy.json
}

data "aws_iam_policy_document" "webhook_lambda_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "kms_decrypt_policy_document" {
  statement {
    sid     = "WebhookLambdaKms"
    actions = [
      "kms:Get*",
      "kms:List*",
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]

    resources = [
      var.release_bucket_kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "kms_decrypt_policy" {
  name   = "${var.project_name}-webhook-kms-policy"

  policy = data.aws_iam_policy_document.kms_decrypt_policy_document.json
}

resource "aws_iam_role_policy_attachment" "webhook_lambda_execution_policy" {
  role       = aws_iam_role.webhook_lambda_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "webhook_lambda_vpc_access_policy" {
  role       = aws_iam_role.webhook_lambda_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "webhook_lambda_s3_access_policy" {
  role       = aws_iam_role.webhook_lambda_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "webhook_lambda_secrets_manager_access_policy" {
  role       = aws_iam_role.webhook_lambda_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "webhook_lambda_kms_policy" {
  role       = aws_iam_role.webhook_lambda_role.name
  policy_arn = aws_iam_policy.kms_decrypt_policy.arn
}