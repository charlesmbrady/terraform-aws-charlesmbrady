###############################################################################
#### AgentCore Infrastructure
#### Amazon Bedrock AgentCore for conversational AI
###############################################################################

module "agentcore" {
  source = "./modules/agentcore"

  # Environment and naming
  environment_tag = var.environment_tag
  project_name    = var.root_project_name_prefix

  # Infrastructure dependencies
  kms_key_id                          = var.kms_key_id
  iam_permissions_boundary_policy_arn = data.aws_iam_policy.role_permissions_boundary.arn
  region                              = data.aws_region.main.name
  account_id                          = data.aws_caller_identity.main.account_id

  # Tool Lambda configuration
  tool_lambda_arn  = module.charlesmbrady_middleware_lambda.function_arn
  tool_lambda_name = local.services_middleware_app_name

  # AgentCore configuration
  agent_name            = var.agentcore_agent_name
  agent_instruction     = var.agentcore_agent_instruction
  agent_description     = var.agentcore_agent_description
  foundation_model      = var.agentcore_foundation_model
  enable_memory         = var.agentcore_enable_memory
  memory_retention_days = var.agentcore_memory_retention_days
  # DIY RAG configuration
  rag_enabled     = var.agentcore_rag_enabled
  rag_bucket_name = var.agentcore_rag_bucket_name

  # Cognito identity configuration
  cognito_user_pool_arn = aws_cognito_user_pool.charlesmbrady.arn
  cognito_user_pool_id  = aws_cognito_user_pool.charlesmbrady.id
  cognito_client_ids    = [
    aws_cognito_user_pool_client.mockdat.id,
    aws_cognito_user_pool_client.apps.id,
  ]
}
