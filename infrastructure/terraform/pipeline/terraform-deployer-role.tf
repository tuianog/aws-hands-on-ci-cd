locals {
  deployer_account_id = local.account
  deployer_role_name  = "terraform-deployer-role-test"
}

resource "aws_iam_role" "terraform-deployer-role" {
  name = local.deployer_role_name

  assume_role_policy = data.aws_iam_policy_document.terraform-deployer-assume-role-policy.json
}

data "aws_iam_policy_document" "terraform-deployer-assume-role-policy" {
  statement {
    sid     = "AllowRunningTerraformDeployerRole"
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type = "AWS"
      identifiers = [local.account, local.deployer_account_id]
    }
  }
}

resource "aws_iam_role_policy" "terraform-deployer-role-policy" {
  name   = "terraform-deployer-role-policy"
  role   = aws_iam_role.terraform-deployer-role.id
  policy = data.aws_iam_policy_document.terraform-deployer-role-policy.json
}

data "aws_iam_policy_document" "terraform-deployer-role-policy" {
  statement {
    actions = [
      "acm:*",
      "apigateway:*",
      "appsync:*",
      "athena:*",
      "autoscaling:*",
      "cloudwatch:*",
      "cloudfront:*",
      "codebuild:*",
      "codepipeline:*",
      "cognito-identity:*",
      "cognito-idp:*",
      "dynamodb:*",
      "ec2:*",
      "ecr:*",
      "es:*",
      "events:*",
      "execute-api:Invoke",
      "firehose:*",
      "glue:PutResourcePolicy",
      "iam:AttachRolePolicy",
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:CreateRole",
      "iam:CreateServiceLinkedRole",
      "iam:DeletePolicy",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:DeletePolicyVersion",
      "iam:DetachRolePolicy",
      "iam:Get*",
      "iam:List*",
      "iam:PassRole",
      "iam:PutRolePolicy",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRoleDescription",
      "kinesis:*",
      "kms:UpdateKeyDescription",
      "kms:ScheduleKeyDeletion",
      "kms:List*",
      "kms:Get*",
      "kms:Describe*",
      "kms:CreateKey",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrpyt",
      "lambda:*",
      "logs:*",
      "mobiletargeting:*",
      "route53:*",
      "s3:*",
      "secretsmanager:*",
      "sns:*",
      "sqs:*",
      "waf-regional:*",
      "waf:*",
      "states:*"
    ]

    resources = ["*"]
  }
}
