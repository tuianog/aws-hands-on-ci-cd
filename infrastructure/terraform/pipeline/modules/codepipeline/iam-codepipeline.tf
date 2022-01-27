# CodePipeline role
data "aws_iam_policy_document" "codepipeline-role-policy" {
  statement {
    actions = [
      "cloudwatch:*",
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "codecommit:CancelUploadArchive",
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:GetUploadArchiveStatus",
      "codecommit:UploadArchive",
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision",
      "lambda:InvokeFunction",
      "lambda:ListFunctions",
      "s3:*",
      "sns:*",
      "kms:Decrypt"
    ]

    resources = ["*"]
  }

  statement {
    actions = ["sts:AssumeRole"]

    resources = [var.terraform_deployer_arn]
  }
}

data "aws_iam_policy_document" "codepipeline-role-policy-document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codepipeline" {
  name               = "${var.project_name}-${var.region}-${var.stage}-pipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline-role-policy-document.json
}

resource "aws_iam_role_policy" "codepipeline-role-policy" {
  name   = "${aws_iam_role.codepipeline.name}-policy"
  role   = aws_iam_role.codepipeline.id
  policy = data.aws_iam_policy_document.codepipeline-role-policy.json
}