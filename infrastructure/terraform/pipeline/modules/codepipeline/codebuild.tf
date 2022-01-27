# Build stage
resource "aws_codebuild_project" "build" {
  name        = "${var.project_name}-${var.stage}-build"
  description = "CodeBuild Project ${var.project_name} for build stage"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:1.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name = "DEPLOY_PROJECT_NAME"
      value = var.deploy_project_name
    }

    environment_variable {
      name = "SOURCE_ARTIFACT"
      value = local.artifact_source_output
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "infrastructure/terraform/pipeline/modules/codepipeline/buildspecs/buildspec-build.yml"
  }

  service_role = aws_iam_role.code-build-role.arn
}

# Plan stage
resource "aws_codebuild_project" "plan" {
  name        = "${var.project_name}-${var.stage}-plan"
  description = "CodeBuild Project ${var.project_name} for plan stage"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:1.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name = "DEPLOY_PROJECT_NAME"
      value = var.deploy_project_name
    }

    environment_variable {
      name = "DEPLOY_PROJECT_VARIABLES_FILE"
      value = var.deploy_project_variables_file
    }

    environment_variable {
      name = "DEPLOY_PROJECT_VARIABLES_CONTENT_B64"
      value = data.local_file.deploy_project_variables_file.content_base64
    }

    environment_variable {
      name = "DEPLOY_PROJECT_BACKEND_CONFIG_FILE"
      value = var.deploy_project_backend_config_file
    }

    environment_variable {
      name = "DEPLOY_PROJECT_BACKEND_CONFIG_CONTENT_B64"
      value = data.local_file.deploy_project_backend_config_file.content_base64
    }

    environment_variable {
      name = "BUILD_ARTIFACT"
      value = local.artifact_build_output
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "infrastructure/terraform/pipeline/modules/codepipeline/buildspecs/buildspec-plan.yml"
  }

  service_role = aws_iam_role.code-build-role.arn
}

# Apply stage
resource "aws_codebuild_project" "apply" {
  name        = "${var.project_name}-${var.stage}-apply"
  description = "CodeBuild Project ${var.project_name} for apply stage"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:1.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name = "DEPLOY_PROJECT_NAME"
      value = var.deploy_project_name
    }

    environment_variable {
      name = "DEPLOY_PROJECT_BACKEND_CONFIG_FILE"
      value = var.deploy_project_backend_config_file
    }

    environment_variable {
      name = "DEPLOY_PROJECT_BACKEND_CONFIG_CONTENT_B64"
      value = data.local_file.deploy_project_backend_config_file.content_base64
    }

    environment_variable {
      name = "BUILD_ARTIFACT"
      value = local.artifact_build_output
    }

    environment_variable {
      name = "PLAN_ARTIFACT"
      value = local.artifact_plan_output
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "infrastructure/terraform/pipeline/modules/codepipeline/buildspecs/buildspec-apply.yml"
  }

  service_role = aws_iam_role.code-build-role.arn
}

# Needed for plan/apply Codebuilds to access this file before committing
# References files content with B64
# Useful when creating a new environment
# If the files already exist and need to be updated, terraform apply on the pipeline needs to be run again
data "local_file" "deploy_project_backend_config_file" {
  filename = var.deploy_project_backend_config_file
}

data "local_file" "deploy_project_variables_file" {
  filename = var.deploy_project_variables_file
}