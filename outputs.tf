###############################################################################
#### Outputs
#### Define your module attributes, aka outputs.
###############################################################################

output "account_id" {
  value = data.aws_caller_identity.main.account_id
}

output "region" {
  value = data.aws_region.main.name
}

output "availability_zone_primary_name" {
  value = data.aws_availability_zone.primary.name
}

###############################################################################
#### AgentCore Outputs
###############################################################################

output "agentcore_runtime_arn" {
  description = "ARN of the AgentCore runtime"
  value       = module.agentcore.runtime_arn
}

output "agentcore_runtime_id" {
  description = "ID of the AgentCore runtime (use this for agent invocations)"
  value       = module.agentcore.runtime_id
}

output "agentcore_endpoint_url" {
  description = "URL of the AgentCore runtime endpoint"
  value       = module.agentcore.endpoint_url
}

output "agentcore_gateway_id" {
  description = "ID of the AgentCore gateway"
  value       = module.agentcore.gateway_id
}

output "agentcore_iam_role_arn" {
  description = "ARN of the IAM role for AgentCore runtime"
  value       = module.agentcore.iam_role_arn
}

output "agentcore_memory_table_name" {
  description = "Name of the DynamoDB table for AgentCore conversation memory"
  value       = module.agentcore.memory_table_name
}

output "agentcore_runtime_arn_ssm_parameter" {
  description = "SSM parameter name containing the AgentCore runtime ARN"
  value       = module.agentcore.runtime_arn_ssm_parameter
}

output "agentcore_runtime_id_ssm_parameter" {
  description = "SSM parameter name containing the AgentCore runtime ID"
  value       = module.agentcore.runtime_id_ssm_parameter
}

output "agentcore_endpoint_url_ssm_parameter" {
  description = "SSM parameter name containing the AgentCore endpoint URL"
  value       = module.agentcore.endpoint_url_ssm_parameter
}

output "agentcore_gateway_id_ssm_parameter" {
  description = "SSM parameter name containing the AgentCore gateway ID"
  value       = module.agentcore.gateway_id_ssm_parameter
}

output "agentcore_log_group_name" {
  description = "CloudWatch log group name for AgentCore"
  value       = module.agentcore.log_group_name
}

output "agentcore_rag_bucket_name" {
  description = "S3 bucket name storing DIY RAG embeddings (if enabled)"
  value       = module.agentcore.rag_bucket_name
}


