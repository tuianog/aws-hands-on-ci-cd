# CodeBuild role
data "aws_iam_policy_document" "codebuild-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codebuild-role-policy" {
  statement {
    actions = [
      "cloudwatch:*",
      "codebuild:*",
      "codedeploy:*",
      "ec2:*",
      "iam:*",
      "lambda:*",
      "logs:*",
      "s3:*",
      "ssm:Get*",
      "dynamodb:*",
      "ecr:*"
    ]

    resources = ["*"]
  }

  statement {
    actions = ["sts:AssumeRole"]

    resources = [var.terraform_deployer_arn]
  }
}

resource "aws_iam_role_policy" "codebuild-role-policy" {
  name   = "${aws_iam_role.code-build-role.name}-policy"
  role   = aws_iam_role.code-build-role.id
  policy = data.aws_iam_policy_document.codebuild-role-policy.json
}

resource "aws_iam_role" "code-build-role" {
  name               = "${var.project_name}-${var.stage}-code-build-role"
  description        = "Allows CodeBuild to call AWS services"
  assume_role_policy = data.aws_iam_policy_document.codebuild-assume-role.json
}