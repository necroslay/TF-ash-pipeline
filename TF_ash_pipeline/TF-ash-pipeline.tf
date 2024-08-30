// iam policy for cloudwatch
resource "aws_iam_role_policy" "codebuild_cloudwatch_policy" {
  name = "codebuild_cloudwatch_policy"
  role = aws_iam_role.ash_codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:*:*:log-group:/aws/codebuild/*",
          "arn:aws:logs:*:*:log-group:/aws/codebuild/*:log-stream:*"
        ]
      }
    ]
  })
}

// iam policy attachment for cloudwatch
resource "aws_iam_policy_attachment" "codebuild_cloudwatch_policy_attachment" {
  name       = "codebuild_cloudwatch_policy_attachment"
  roles      = [aws_iam_role.ash_codebuild_role.name]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}
resource "aws_iam_role" "ash_codebuild_role" {
  name = "ash_codebuild_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}

// iam policy attachment for codebuild role
resource "aws_iam_policy_attachment" "codebuild_role_policy_attachment" {
  name       = "codebuild_role_policy_attachment"
  roles      = [aws_iam_role.ash_codebuild_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

// iam codepipeline role
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

// iam policy for codepipeline
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.reportStorage.arn,
          "${aws_s3_bucket.reportStorage.arn}/*"
        ]
      },
      {
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Effect   = "Allow"
        Resource = aws_codebuild_project.ash_codebuild_project.arn
      },
    ]
  })
}

// s3 bucket to store report
resource "aws_s3_bucket" "reportStorage" {
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256" # or "aws:kms" if you want to use AWS KMS
      }
    }
  }

  lifecycle_rule {
    id      = "log"
    enabled = true

    prefix = "log/"
    tags = {
      "rule"      = "log"
      "autoclean" = "true"
    }

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
  tags = {
    Name        = "reportStorage"
    Environment = "Dev"
  }
}

// access rules for s3 bucket
resource "aws_s3_bucket_public_access_block" "secure_bucket_block" {
  bucket = aws_s3_bucket.reportStorage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// codebuild
resource "aws_codebuild_project" "ash_codebuild_project" {
  name          = "terraform-refactored-ash"
  description   = "security checks for code"
  build_timeout = 60
  service_role  = aws_iam_role.ash_codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/terraform-refactored-ash"
      stream_name = "log-stream"
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/awslabs/automated-security-helper.git"
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = true
    }

    buildspec = <<-EOF
    version: 0.2

    phases:
      install:
        commands:
          - echo "Cloning ASH"
          - git clone https://github.com/aws-samples/automated-security-helper.git /tmp/ash
      build:
        commands:
          - echo "Running ASH..."
          - "if /tmp/ash/ash --source-dir .; then echo scan completed; else echo found vulnerabilies && scan_fail=1 ;fi"
      post_build:
        commands:
          - echo "Uploading report to s3://${aws_s3_bucket.reportStorage.bucket}/ash-pipeline/source_out/"
          - aws s3 cp ./ash_output/aggregated_results.txt s3://${aws_s3_bucket.reportStorage.bucket}/ash-pipeline/source_out/
    artifacts:
      files:
        - '**/*'
EOF

  }

  source_version = "master"

  tags = {
    Environment = "Test"
  }
}

// codepipline
resource "aws_codepipeline" "ash_pipeline" {
  name     = "ash_pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.reportStorage.bucket
  }

  stage {
    name = "Source"

    action {
      name             = "SourceRepo"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = "var.github_user // INSERT name of github profile
        Repo       = "var.repo_name" // INSERT repo name
        Branch     = "var.branch_name" // INSERT branch name
        OAuthToken = var.github_oauth_token
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]

      configuration = {
        ProjectName = aws_codebuild_project.ash_codebuild_project.name
      }
    }
  }
}

