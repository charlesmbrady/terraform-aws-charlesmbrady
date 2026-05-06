###############################################################################
#### AgentCore Module Outputs
###############################################################################

###############################################################################
#### AgentCore Runtime Outputs
###############################################################################

output "runtime_name" {
  description = "Name of the AgentCore runtime"
  value       = aws_bedrockagentcore_agent_runtime.main.agent_runtime_name
}

output "runtime_id" {
  description = "ID of the AgentCore runtime"
  value       = aws_bedrockagentcore_agent_runtime.main.agent_runtime_id
}

output "runtime_arn" {
  description = "ARN of the AgentCore runtime"
  value       = aws_bedrockagentcore_agent_runtime.main.agent_runtime_arn
}

output "runtime_endpoint_name" {
  description = "Name of the service-managed default AgentCore runtime endpoint qualifier"
  value       = "DEFAULT"
}

output "runtime_endpoint_arn" {
  description = "ARN of the default AgentCore runtime endpoint. AgentCore manages DEFAULT through runtime updates, so this module does not manage or expose an endpoint resource ARN."
  value       = null
}

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

