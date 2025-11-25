###############################################################################
#### AgentCore Workload Identity Provider
#### Allows AgentCore to accept Cognito JWT tokens for authentication
###############################################################################

resource "aws_bedrockagentcore_workload_identity_provider" "cognito" {
  count = var.cognito_user_pool_arn != "" ? 1 : 0

  name        = "${local.agentcore_name}_cognito_identity"
  description = "Cognito OIDC identity provider for ${local.agentcore_name}"

  oidc_configuration {
    issuer_url = "https://cognito-idp.${var.region}.amazonaws.com/${var.cognito_user_pool_id}"
    
    # Cognito client IDs that are allowed to authenticate
    client_ids = var.cognito_client_ids
    
    # JWT claims mapping
    user_id_claim = "sub"  # Cognito's user ID claim
  }

  tags = {
    Name        = "${local.agentcore_name}_cognito_identity"
    Environment = var.environment_tag
  }
}
