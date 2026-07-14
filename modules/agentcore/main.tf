###############################################################################
#### AgentCore Module - Main Configuration
###############################################################################

locals {
  # agent_name already encodes the project context (e.g. "jamcam-session-config-assistant"),
  # so we don't prepend var.project_name and end up with "jamcam-jamcam-..." duplication.
  # All AWS naming limits (48 for runtime/memory/gateway, 64 for IAM, 128 for CodeBuild)
  # are satisfied without sanitization.
  base_us = replace("${var.agent_name}_${var.environment_tag}", "-", "_")
  base_hy = "${var.agent_name}-${var.environment_tag}"

  agentcore_name         = local.base_us # AWS regex: ^[a-zA-Z][a-zA-Z0-9_]{0,47}$
  memory_name            = "${local.base_us}_mem"
  gateway_name           = "${local.base_hy}-gw" # <=48 chars, alnum + hyphen
  codebuild_role_name    = "${local.base_hy}-cb-role"
  codebuild_project_name = "${local.base_hy}-build"
  basic_agent_ecr_name   = lower("${local.base_hy}-basic-agent")

  runtime_source_bucket_name = format(
    "%s-%s-src",
    substr(local.agentcore_bucket_base, 0, 43),
    var.account_id
  )
}

###############################################################################
#### AgentCore Runtime
###############################################################################

resource "aws_bedrockagentcore_agent_runtime" "main" {
  agent_runtime_name = local.agentcore_name
  role_arn           = aws_iam_role.agentcore_runtime.arn
  description        = var.agent_description

  depends_on = [aws_codebuild_project.basic_agent_image]

  # Container-based artifact configuration - uses ARM64 image built by CodeBuild
  agent_runtime_artifact {
    container_configuration {
      container_uri = "${aws_ecr_repository.basic_agent.repository_url}:latest"
    }
  }

  # Minimal network configuration (PUBLIC or VPC)
  network_configuration {
    network_mode = "PUBLIC"
  }

  lifecycle_configuration {
    idle_runtime_session_timeout = var.idle_runtime_session_timeout
    max_lifetime                 = var.max_lifetime
  }

  # Pass model + instruction + rag bucket + memory ID to the runtime container/code
  environment_variables = {
    AGENT_INSTRUCTION = var.agent_instruction
    FOUNDATION_MODEL  = var.foundation_model
    RAG_BUCKET        = var.rag_enabled ? local.rag_bucket_effective_name : ""
    MEMORY_ID         = var.enable_memory ? aws_bedrockagentcore_memory.main[0].id : ""
    TOOL_LAMBDA_NAME  = var.tool_lambda_name
    TOOL_LAMBDA_ARN   = var.tool_lambda_arn
    # Explicitly pass region to runtime to avoid cross-region defaults
    AGENTCORE_REGION = var.region
  }

  tags = {
    Name        = local.agentcore_name
    Environment = var.environment_tag
  }
}

###############################################################################
#### AgentCore Gateway
###############################################################################

resource "aws_bedrockagentcore_gateway" "main" {
  name            = local.gateway_name
  protocol_type   = "MCP"     # Valid values: MCP
  authorizer_type = "AWS_IAM" # Using IAM auth (no JWT authorizer block required)
  role_arn        = aws_iam_role.agentcore_runtime.arn

  tags = {
    Name        = local.gateway_name
    Environment = var.environment_tag
  }
}

###############################################################################
#### AgentCore Gateway Tool - Lambda Integration
###############################################################################
# Note: aws_bedrockagentcore_gateway_tool does not exist in the provider.
# Tool integration is handled at invocation time via Lambda permissions.
# The gateway already has IAM role permissions to invoke the Lambda tool.

###############################################################################
#### AgentCore Memory Configuration
###############################################################################

resource "aws_bedrockagentcore_memory" "main" {
  count = var.enable_memory ? 1 : 0

  name                  = local.memory_name
  event_expiry_duration = var.memory_retention_days # Days (7-365)
  description           = "Persistent memory for ${local.agentcore_name}"

  tags = {
    Name        = local.memory_name
    Environment = var.environment_tag
  }
}

###############################################################################
#### DIY RAG Lightweight Embeddings Storage (S3)
###############################################################################

locals {
  # S3 bucket naming must be lowercase letters, numbers, and hyphens (no underscores, no uppercase).
  # Derive a base from agentcore_name by replacing underscores with hyphens and lowercasing.
  agentcore_bucket_base     = lower(replace(local.agentcore_name, "_", "-"))
  rag_bucket_effective_name = var.rag_bucket_name != "" ? lower(replace(var.rag_bucket_name, "_", "-")) : "${local.agentcore_bucket_base}-rag-embeddings"
}

resource "aws_s3_bucket" "rag_embeddings" {
  count         = var.rag_enabled ? 1 : 0
  bucket        = local.rag_bucket_effective_name
  force_destroy = true

  tags = {
    Name        = local.rag_bucket_effective_name
    Purpose     = "DIY-RAG-Embeddings"
    Environment = var.environment_tag
  }
}

resource "aws_s3_bucket_public_access_block" "rag_embeddings" {
  count                   = var.rag_enabled ? 1 : 0
  bucket                  = aws_s3_bucket.rag_embeddings[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_ssm_parameter" "rag_bucket_name" {
  count       = var.rag_enabled ? 1 : 0
  name        = "/${var.project_name}/${var.environment_tag}/agentcore/rag/bucket-name"
  description = "S3 bucket name storing DIY RAG embeddings JSON"
  type        = "String"
  value       = aws_s3_bucket.rag_embeddings[0].bucket

  tags = {
    Name        = "agentcore-rag-bucket-name"
    Environment = var.environment_tag
  }
}

###############################################################################
#### NOTE: SSM parameters for runtime/gateway ID/ARN removed
###############################################################################
# The provider does not export runtime or gateway id/arn attributes. References
# to those attributes caused Terraform errors. These SSM parameters are removed
# to ensure a successful apply without unsupported attribute lookups.


###############################################################################
#### CloudWatch Log Group for AgentCore
###############################################################################

## NOTE: Do not pre-create a custom CloudWatch log group. The service creates
## log groups under /aws/bedrock-agentcore/runtimes/ automatically. Pre-creating
## a mismatched path (e.g. /aws/bedrock/agentcore/...) leads to confusion when
## logs appear empty. Retaining no manual log group ensures correct automatic
## log stream generation.

###############################################################################
#### Basic Agent ECR Repository (for container-based runtime)
###############################################################################

resource "aws_ecr_repository" "basic_agent" {
  name                 = local.basic_agent_ecr_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${local.basic_agent_ecr_name}-repository"
    Environment = var.environment_tag
    Module      = "ECR"
  }
}

###############################################################################
#### CodeBuild Runtime Source Archive
###############################################################################

resource "aws_s3_bucket" "runtime_source" {
  bucket        = local.runtime_source_bucket_name
  force_destroy = true

  tags = {
    Name        = local.runtime_source_bucket_name
    Purpose     = "AgentCore-CodeBuild-Source"
    Environment = var.environment_tag
  }
}

resource "aws_s3_bucket_public_access_block" "runtime_source" {
  bucket                  = aws_s3_bucket.runtime_source.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "archive_file" "runtime_source" {
  type        = "zip"
  source_dir  = "${path.module}/runtime_code"
  output_path = "${path.root}/.terraform/${local.agentcore_name}-runtime-source.zip"
}

resource "aws_s3_object" "runtime_source" {
  bucket = aws_s3_bucket.runtime_source.id
  key    = "agentcore/runtime-source.zip"
  source = data.archive_file.runtime_source.output_path
  etag   = data.archive_file.runtime_source.output_md5
}

###############################################################################
#### CodeBuild Project - Build ARM64 Basic Agent Image
###############################################################################

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "codebuild_role" {
  name = local.codebuild_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  inline_policy {
    name = "CodeBuildPolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "CloudWatchLogs"
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
          ]
          Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/*"
        },
        {
          Sid    = "S3SourceBucketAccess"
          Effect = "Allow"
          Action = [
            "s3:GetBucketAcl",
            "s3:GetBucketLocation",
          ]
          Resource = aws_s3_bucket.runtime_source.arn
        },
        {
          Sid    = "S3SourceObjectAccess"
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:GetObjectVersion",
          ]
          Resource = "${aws_s3_bucket.runtime_source.arn}/*"
        },
        {
          Sid    = "ECRAccess"
          Effect = "Allow"
          Action = [
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:GetAuthorizationToken",
            "ecr:PutImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
          ]
          Resource = [
            aws_ecr_repository.basic_agent.arn,
            "*",
          ]
        },
      ]
    })
  }

  tags = {
    Name        = local.codebuild_role_name
    Environment = var.environment_tag
    Module      = "IAM"
  }
}

resource "aws_codebuild_project" "basic_agent_image" {
  name         = local.codebuild_project_name
  description  = "Build basic agent Docker image for ${local.base_hy}"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    type            = "ARM_CONTAINER"
    compute_type    = "BUILD_GENERAL1_LARGE"
    image           = "aws/codebuild/amazonlinux2-aarch64-standard:3.0"
    privileged_mode = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.name
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.basic_agent.name
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
  }

  source {
    type      = "S3"
    location  = "${aws_s3_bucket.runtime_source.bucket}/${aws_s3_object.runtime_source.key}"
    buildspec = "buildspec.yml"
  }

  tags = {
    Name        = local.codebuild_project_name
    Environment = var.environment_tag
    Module      = "CodeBuild"
  }
}

