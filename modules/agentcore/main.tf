###############################################################################
#### AgentCore Module - Main Configuration
###############################################################################

locals {
  # Use underscores instead of hyphens to comply with AWS naming regex: ^[a-zA-Z][a-zA-Z0-9_]{0,47}$
  agentcore_name = replace("${var.project_name}_${var.agent_name}_${var.environment_tag}", "-", "_")
  
  # Gateway requires hyphen-based naming: ^([0-9a-zA-Z][-]?){1,100}$
  gateway_name = "${var.project_name}-${var.agent_name}-${var.environment_tag}-gateway"
}

###############################################################################
#### AgentCore Runtime
###############################################################################

resource "aws_bedrockagentcore_agent_runtime" "main" {
  agent_runtime_name = local.agentcore_name
  role_arn           = aws_iam_role.agentcore_runtime.arn
  description        = var.agent_description

  depends_on = [aws_s3_object.runtime_code]

  # Required artifact configuration - points to managed S3 code package
  agent_runtime_artifact {
    code_configuration {
      # Production runtime with full strands tooling
      entry_point = ["main.py"]
      # Use currently supported Bedrock AgentCore Python runtime version
      runtime     = "PYTHON_3_12"
      code {
        s3 {
          bucket = aws_s3_bucket.runtime_code.id
          prefix = local.runtime_code_key
        }
      }
    }
  }

  # Minimal network configuration (PUBLIC or VPC)
  network_configuration {
    network_mode = "PUBLIC"
  }

  # Pass model + instruction + rag bucket to the runtime container/code
  environment_variables = {
    AGENT_INSTRUCTION = var.agent_instruction
    FOUNDATION_MODEL  = var.foundation_model
    RAG_BUCKET        = var.rag_enabled ? local.rag_bucket_effective_name : ""
  }

  tags = {
    Name        = local.agentcore_name
    Environment = var.environment_tag
  }
}

###############################################################################
#### AgentCore Runtime Endpoint
###############################################################################

## NOTE: The prior "aws_bedrockagentcore_agent_runtime_endpoint" resource has been removed.
## If endpoints become available/required in the provider schema later, reintroduce accordingly.

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

  name                  = "${local.agentcore_name}_memory"
  event_expiry_duration = var.memory_retention_days # Days (7-365)
  description           = "Persistent memory for ${local.agentcore_name}"

  tags = {
    Name        = "${local.agentcore_name}_memory"
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

###############################################################################
#### Runtime Code Artifacts Storage (S3)
###############################################################################

locals {
  runtime_code_bucket_name = "${local.agentcore_bucket_base}-runtime-code"
  runtime_code_key         = "agent-runtime/code.zip"
}

# S3 bucket for runtime code artifacts
resource "aws_s3_bucket" "runtime_code" {
  bucket        = local.runtime_code_bucket_name
  force_destroy = true

  tags = {
    Name        = local.runtime_code_bucket_name
    Purpose     = "AgentCore-Runtime-Code"
    Environment = var.environment_tag
  }
}

resource "aws_s3_bucket_public_access_block" "runtime_code" {
  bucket                  = aws_s3_bucket.runtime_code.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Package runtime code into zip archive
# NOTE: This uses source_dir which does NOT install Python dependencies.
# For production, run: modules/agentcore/runtime_code/build_package.sh
# to create a zip with vendored dependencies, then point to that zip.
data "archive_file" "runtime_code" {
  type        = "zip"
  source_dir  = "${path.module}/runtime_code"
  output_path = "${path.module}/.terraform/runtime_code.zip"
  excludes    = ["package.sh", "build_package.sh", "deploy_full.sh", "deploy_full_fixed.sh", "force_recreate.sh", "README.md", ".DS_Store", "build/", "*.zip", "main_minimal.py", "main_simple.py", "main_basic_agent.py", "requirements_minimal.txt"]
}

# Upload runtime code to S3
resource "aws_s3_object" "runtime_code" {
  bucket = aws_s3_bucket.runtime_code.id
  key    = local.runtime_code_key
  source = data.archive_file.runtime_code.output_path
  etag   = data.archive_file.runtime_code.output_md5

  tags = {
    Name        = "agentcore-runtime-code"
    Environment = var.environment_tag
  }
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

