###############################################################################
#### AgentCore Module Outputs
###############################################################################

###############################################################################
#### AgentCore Runtime Outputs
###############################################################################

## Removed runtime_arn and runtime_id outputs (provider does not export arn/id)

output "runtime_name" {
  description = "Name of the AgentCore runtime"
  value       = aws_bedrockagentcore_agent_runtime.main.agent_runtime_name
}

## Runtime Endpoint outputs removed (endpoint resource deprecated/not present)

###############################################################################
#### Gateway Outputs
###############################################################################

## Removed gateway_id and gateway_arn outputs (provider does not export arn/id)

###############################################################################
#### IAM Outputs
###############################################################################

output "iam_role_arn" {
  description = "ARN of the IAM role for AgentCore runtime"
  value       = aws_iam_role.agentcore_runtime.arn
}

output "iam_role_name" {
  description = "Name of the IAM role for AgentCore runtime"
  value       = aws_iam_role.agentcore_runtime.name
}

###############################################################################
#### DynamoDB Memory Outputs
###############################################################################

output "memory_table_name" {
  description = "Name of the DynamoDB table for conversation memory"
  value       = aws_dynamodb_table.agentcore_memory.name
}

output "memory_table_arn" {
  description = "ARN of the DynamoDB table for conversation memory"
  value       = aws_dynamodb_table.agentcore_memory.arn
}

###############################################################################
#### SSM Parameter Outputs
###############################################################################


## Removed endpoint & qualifier SSM parameter outputs (endpoint resource removed)

## Removed SSM parameter outputs for runtime/gateway id/arn (parameters deleted)

###############################################################################
#### DIY RAG Outputs
###############################################################################

output "rag_bucket_name" {
  description = "Name of the S3 bucket storing RAG embeddings JSON (if enabled)"
  value       = var.rag_enabled ? aws_s3_bucket.rag_embeddings[0].bucket : null
}

output "rag_bucket_name_ssm_parameter" {
  description = "SSM parameter name holding RAG bucket name (if enabled)"
  value       = var.rag_enabled ? aws_ssm_parameter.rag_bucket_name[0].name : null
}

###############################################################################
#### Runtime Code Outputs
###############################################################################

output "runtime_code_bucket_name" {
  description = "Name of the S3 bucket storing runtime code artifacts"
  value       = aws_s3_bucket.runtime_code.bucket
}

output "runtime_code_s3_key" {
  description = "S3 key of the uploaded runtime code package"
  value       = aws_s3_object.runtime_code.key
}

output "runtime_code_version" {
  description = "Version (ETag) of the runtime code package"
  value       = aws_s3_object.runtime_code.etag
}

#### CloudWatch Outputs (No manual log group)
###############################################################################

# NOTE: Runtime log groups are created automatically under:
# /aws/bedrock-agentcore/runtimes/<runtime-id>-<agentcore_name>/runtime-logs
# Explicit outputs removed because we no longer create a fixed log group.

###############################################################################
#### Composite Outputs
###############################################################################

output "agentcore_name" {
  description = "Generated name for the AgentCore agent"
  value       = local.agentcore_name
}

output "memory_enabled" {
  description = "Whether memory is enabled for this AgentCore runtime"
  value       = var.enable_memory
}

