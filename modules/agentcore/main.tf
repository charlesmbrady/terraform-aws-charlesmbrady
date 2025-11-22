###############################################################################
#### AgentCore Module - Main Configuration
###############################################################################

locals {
  agentcore_name = "${var.project_name}-${var.agent_name}-${var.environment_tag}"
}

###############################################################################
#### AgentCore Runtime
###############################################################################

resource "aws_bedrockagentcore_agent_runtime" "main" {
  runtime_name        = local.agentcore_name
  foundation_model_id = var.foundation_model
  role_arn            = aws_iam_role.agentcore_runtime.arn
  instruction         = var.agent_instruction
  description         = var.agent_description

  # Session timeout configuration
  idle_session_ttl_in_seconds = 600

  # Enhanced prompt configuration with inference parameters
  prompt_override_configuration {
    prompt_configurations {
      prompt_type = "ORCHESTRATION"

      inference_configuration {
        temperature = 0.7
        top_p       = 0.9
        top_k       = 250
        max_length  = 2048
      }
    }
  }

  tags = {
    Name        = local.agentcore_name
    Environment = var.environment_tag
  }
}

###############################################################################
#### AgentCore Runtime Endpoint
###############################################################################

resource "aws_bedrockagentcore_runtime_endpoint" "default" {
  runtime_id = aws_bedrockagentcore_agent_runtime.main.id
  qualifier  = "DEFAULT"

  tags = {
    Name        = "${local.agentcore_name}-endpoint-default"
    Environment = var.environment_tag
  }
}

###############################################################################
#### AgentCore Gateway
###############################################################################

resource "aws_bedrockagentcore_gateway" "main" {
  gateway_name = "${local.agentcore_name}-gateway"

  routing_config {
    default_runtime_id = aws_bedrockagentcore_agent_runtime.main.id
  }

  tags = {
    Name        = "${local.agentcore_name}-gateway"
    Environment = var.environment_tag
  }
}

###############################################################################
#### AgentCore Gateway Tool - Lambda Integration
###############################################################################

resource "aws_bedrockagentcore_gateway_tool" "lambda_tool" {
  gateway_id = aws_bedrockagentcore_gateway.main.id

  tool_config {
    lambda_tool {
      lambda_arn  = var.tool_lambda_arn
      name        = var.tool_lambda_name
      description = "API services tool for ${var.project_name} platform"
    }
  }
}

###############################################################################
#### AgentCore Memory Configuration
###############################################################################

resource "aws_bedrockagentcore_memory" "main" {
  count = var.enable_memory ? 1 : 0

  runtime_id = aws_bedrockagentcore_agent_runtime.main.id

  storage_config {
    dynamodb_storage {
      table_name = aws_dynamodb_table.agentcore_memory.name
    }
  }

  retention_config {
    retention_days = var.memory_retention_days
  }
}

###############################################################################
#### DIY RAG Lightweight Embeddings Storage (S3)
###############################################################################

locals {
  rag_bucket_effective_name = var.rag_bucket_name != "" ? var.rag_bucket_name : "${local.agentcore_name}-rag-embeddings"
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
#### SSM Parameters for Runtime Configuration
###############################################################################

# Store runtime ARN for Lambda/frontend access
resource "aws_ssm_parameter" "agentcore_runtime_arn" {
  name        = "/${var.project_name}/${var.environment_tag}/agentcore/runtime-arn"
  description = "ARN of the AgentCore runtime"
  type        = "String"
  value       = aws_bedrockagentcore_agent_runtime.main.arn

  tags = {
    Name        = "agentcore-runtime-arn"
    Environment = var.environment_tag
  }
}

# Store runtime ID for invocations
resource "aws_ssm_parameter" "agentcore_runtime_id" {
  name        = "/${var.project_name}/${var.environment_tag}/agentcore/runtime-id"
  description = "ID of the AgentCore runtime"
  type        = "String"
  value       = aws_bedrockagentcore_agent_runtime.main.id

  tags = {
    Name        = "agentcore-runtime-id"
    Environment = var.environment_tag
  }
}

# Store endpoint URL
resource "aws_ssm_parameter" "agentcore_endpoint_url" {
  name        = "/${var.project_name}/${var.environment_tag}/agentcore/endpoint-url"
  description = "URL of the AgentCore runtime endpoint"
  type        = "String"
  value       = aws_bedrockagentcore_runtime_endpoint.default.endpoint_url

  tags = {
    Name        = "agentcore-endpoint-url"
    Environment = var.environment_tag
  }
}

# Store qualifier
resource "aws_ssm_parameter" "agentcore_runtime_qualifier" {
  name        = "/${var.project_name}/${var.environment_tag}/agentcore/qualifier"
  description = "Runtime qualifier for the AgentCore endpoint"
  type        = "String"
  value       = "DEFAULT"

  tags = {
    Name        = "agentcore-qualifier"
    Environment = var.environment_tag
  }
}

# Store gateway ID
resource "aws_ssm_parameter" "agentcore_gateway_id" {
  name        = "/${var.project_name}/${var.environment_tag}/agentcore/gateway-id"
  description = "ID of the AgentCore gateway"
  type        = "String"
  value       = aws_bedrockagentcore_gateway.main.id

  tags = {
    Name        = "agentcore-gateway-id"
    Environment = var.environment_tag
  }
}


###############################################################################
#### CloudWatch Log Group for AgentCore
###############################################################################

resource "aws_cloudwatch_log_group" "agentcore" {
  name              = "/aws/bedrock/agentcore/${local.agentcore_name}"
  retention_in_days = 30

  tags = {
    Name        = "${local.agentcore_name}-logs"
    Environment = var.environment_tag
  }
}

