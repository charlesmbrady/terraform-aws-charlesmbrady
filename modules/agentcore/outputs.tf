###############################################################################
#### AgentCore Module Outputs
###############################################################################

###############################################################################
#### AgentCore Runtime Outputs
###############################################################################

output "runtime_arn" {
  description = "ARN of the AgentCore runtime"
  value       = aws_bedrockagentcore_agent_runtime.main.arn
}

output "runtime_id" {
  description = "ID of the AgentCore runtime"
  value       = aws_bedrockagentcore_agent_runtime.main.id
}

output "runtime_name" {
  description = "Name of the AgentCore runtime"
  value       = aws_bedrockagentcore_agent_runtime.main.agent_runtime_name
}

###############################################################################
#### Runtime Endpoint Outputs
###############################################################################

output "endpoint_id" {
  description = "ID of the AgentCore runtime endpoint"
  value       = aws_bedrockagentcore_agent_runtime_endpoint.default.id
}

output "endpoint_url" {
  description = "URL of the AgentCore runtime endpoint"
  value       = try(aws_bedrockagentcore_agent_runtime_endpoint.default.endpoint_url, "")
}

###############################################################################
#### Gateway Outputs
###############################################################################

output "gateway_id" {
  description = "ID of the AgentCore gateway"
  value       = aws_bedrockagentcore_gateway.main.id
}

output "gateway_arn" {
  description = "ARN of the AgentCore gateway"
  value       = aws_bedrockagentcore_gateway.main.arn
}

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

output "runtime_arn_ssm_parameter" {
  description = "SSM parameter name for AgentCore runtime ARN"
  value       = aws_ssm_parameter.agentcore_runtime_arn.name
}

output "runtime_id_ssm_parameter" {
  description = "SSM parameter name for AgentCore runtime ID"
  value       = aws_ssm_parameter.agentcore_runtime_id.name
}

output "endpoint_url_ssm_parameter" {
  description = "SSM parameter name for AgentCore endpoint URL"
  value       = aws_ssm_parameter.agentcore_endpoint_url.name
}

output "qualifier_ssm_parameter" {
  description = "SSM parameter name for AgentCore qualifier"
  value       = aws_ssm_parameter.agentcore_runtime_qualifier.name
}

output "gateway_id_ssm_parameter" {
  description = "SSM parameter name for AgentCore gateway ID"
  value       = aws_ssm_parameter.agentcore_gateway_id.name
}

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
#### CloudWatch Outputs
###############################################################################

output "log_group_name" {
  description = "CloudWatch log group name for AgentCore"
  value       = aws_cloudwatch_log_group.agentcore.name
}

output "log_group_arn" {
  description = "CloudWatch log group ARN for AgentCore"
  value       = aws_cloudwatch_log_group.agentcore.arn
}

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

