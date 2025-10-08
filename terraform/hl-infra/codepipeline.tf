locals {
  hl_api_container_name = "hl-api"
}

resource "random_id" "codepipeline_bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "hl-codepipeline-artifacts-${var.environment}-${random_id.codepipeline_bucket_suffix.hex}"

  tags = {
    Name        = "hl-codepipeline-artifacts-${var.environment}"
    Environment = var.environment
    Project     = "hl-api"
  }
}

resource "aws_s3_bucket_versioning" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "codepipeline_artifacts" {
  bucket                  = aws_s3_bucket.codepipeline_artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudwatch_log_group" "codebuild_hl_api" {
  name              = "/aws/codebuild/hl-api-${var.environment}"
  retention_in_days = 14
}

resource "aws_iam_role" "codebuild_hl_api" {
  name = "hl-api-codebuild-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "codebuild_hl_api" {
  name = "hl-api-codebuild-policy-${var.environment}"
  role = aws_iam_role.codebuild_hl_api.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = ["s3:PutObject", "s3:GetObject", "s3:GetObjectVersion", "s3:ListBucket"],
        Resource = [
          aws_s3_bucket.codepipeline_artifacts.arn,
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ],
        Resource = [module.ecr.repository_arn]
      },
      {
        Effect   = "Allow",
        Action   = ["ecr:DescribeRepositories"],
        Resource = [module.ecr.repository_arn]
      },
      {
        Effect   = "Allow",
        Action   = ["ecr:GetAuthorizationToken"],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["logs:DescribeLogGroups"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "codepipeline_hl_api" {
  name = "hl-api-codepipeline-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codepipeline.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "codepipeline_hl_api" {
  name = "hl-api-codepipeline-policy-${var.environment}"
  role = aws_iam_role.codepipeline_hl_api.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"],
        Resource = [
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = ["s3:ListBucket"],
        Resource = [aws_s3_bucket.codepipeline_artifacts.arn]
      },
      {
        Effect   = "Allow",
        Action   = ["codebuild:BatchGetBuilds", "codebuild:StartBuild"],
        Resource = [aws_codebuild_project.hl_api.arn]
      },
      {
        Effect   = "Allow",
        Action   = ["codestar-connections:UseConnection"],
        Resource = [var.codepipeline_github_connection_arn]
      },
      {
        Effect = "Allow",
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService",
          "ecs:DescribeClusters"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = ["iam:PassRole"],
        Resource = [
          aws_iam_role.ecs_task_execution_role.arn,
          aws_iam_role.ecs_task_role.arn
        ]
      }
    ]
  })
}

resource "aws_codebuild_project" "hl_api" {
  name          = "hl-api-${var.environment}"
  description   = "Builds and pushes the hl-api Docker image"
  service_role  = aws_iam_role.codebuild_hl_api.arn
  build_timeout = 30

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "REPOSITORY_URI"
      value = module.ecr.repository_url
    }

    environment_variable {
      name  = "CONTAINER_NAME"
      value = local.hl_api_container_name
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild_hl_api.name
      stream_name = "build"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec/hl-api-buildspec.yml"
  }

  tags = {
    Environment = var.environment
    Project     = "hl-api"
  }

  depends_on = [aws_cloudwatch_log_group.codebuild_hl_api]
}

resource "aws_codepipeline" "hl_api" {
  name     = "hl-api-${var.environment}"
  role_arn = aws_iam_role.codepipeline_hl_api.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.codepipeline_artifacts.bucket
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceOutput"]

      configuration = {
        ConnectionArn        = var.codepipeline_github_connection_arn
        FullRepositoryId     = var.codepipeline_github_repo
        BranchName           = var.codepipeline_github_branch
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.hl_api.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["BuildOutput"]
      version         = "1"

      configuration = {
        ClusterName = module.ecs_cluster.cluster_name
        ServiceName = aws_ecs_service.hl_api.name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  tags = {
    Environment = var.environment
    Project     = "hl-api"
  }

  depends_on = [
    aws_s3_bucket_public_access_block.codepipeline_artifacts,
    aws_s3_bucket_server_side_encryption_configuration.codepipeline_artifacts,
    aws_s3_bucket_versioning.codepipeline_artifacts
  ]
}
