locals {
  # Variables of CodePipeline input/output artifacts
  artifact_source_output = "SourceProject"
  artifact_build_output = "BuildOutput"
  artifact_plan_output = "PlanPhaseOutput"

  s3_branch_key = "${var.s3_branch_prefix}/${var.branch_name}.zip"

  manual_approval_step_flag = var.manual_approval_step == "true" ? [var.manual_approval_step] : []
}

resource "aws_codepipeline" "pipeline" {
  name     = "${var.project_name}-${var.stage}"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifact_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      category = "Source"
      owner    = "AWS"
      name     = "Source"
      provider = "S3"
      version  = "1"

      configuration = {
        S3Bucket             = var.s3_release_bucket
        S3ObjectKey          = local.s3_branch_key
        # AUTO trigger when pushes are done
        PollForSourceChanges = var.pipeline_auto_trigger
      }

      output_artifacts = [local.artifact_source_output]
    }
  }

  stage {
    name = "Build"

    action {
      category = "Build"
      owner    = "AWS"
      name     = "Package"
      provider = "CodeBuild"
      version  = "1"

      configuration = {
        ProjectName   = aws_codebuild_project.build.name
        PrimarySource = local.artifact_source_output
      }

      input_artifacts  = [local.artifact_source_output]
      output_artifacts = [local.artifact_build_output]
    }
  }

  stage {
    name = "Deploy"

    action {
      category  = "Build"
      owner     = "AWS"
      name      = "Plan"
      provider  = "CodeBuild"
      version   = "1"
      run_order = "1"

      configuration = {
        ProjectName   = aws_codebuild_project.plan.name
        PrimarySource = local.artifact_source_output
      }

      input_artifacts  = [local.artifact_source_output, local.artifact_build_output]
      output_artifacts = [local.artifact_plan_output]
    }

    dynamic "action" {
      for_each = local.manual_approval_step_flag
      content {
        name      = "ManualApproval"
        category  = "Approval"
        owner     = "AWS"
        provider  = "Manual"
        version   = "1"
        run_order = "2"
      }
    }

    action {
      category  = "Build"
      owner     = "AWS"
      name      = "Apply"
      provider  = "CodeBuild"
      version   = "1"
      run_order = "3"

      configuration = {
        ProjectName   = aws_codebuild_project.apply.name
        PrimarySource = local.artifact_source_output
      }

      input_artifacts = [local.artifact_source_output, local.artifact_build_output, local.artifact_plan_output]
    }
  }
}