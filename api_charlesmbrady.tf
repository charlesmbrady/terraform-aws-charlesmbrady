locals {
  cognitoAuthorizerName = "CognitoUserPoolAuthorizer-cmb-${var.environment_tag}"
}

module "charlesmbrady_api" {
  source  = "app.terraform.io/charlava/apigw-module/aws"
  version = "1.3.0"

  api_name       = var.charlesmbrady_api_name
  api_stage_name = var.charlesmbrady_api_stage_name
  api_throttling_rate_limit = var.charlesmbrady_api_throttling_rate_limit
  api_throttling_burst_limit = var.charlesmbrady_api_throttling_burst_limit
  api_metrics_enabled = var.charlesmbrady_api_metrics_enabled
  api_logging_level = var.charlesmbrady_api_logging_level
  create_api_key = true
  role_permissions_boundary_policy_name = "AdministratorAccess" #TODO: Replace with more restrictive

  api_template = "../../api_charlesmbrady.yml"
  api_template_vars = {
    charlesmbrady_api_domain_name = var.charlesmbrady_api_domain_name
    cognito_user_pool_arn = aws_cognito_user_pool.charlesmbrady.arn
    lambda_charlesmbrady_middleware_arn = module.charlesmbrady_middleware_lambda.function_arn
    region = data.aws_region.main.name
    cognitoAuthorizerName = local.cognitoAuthorizerName
  }
}

# Cognito Authorizer
resource "aws_api_gateway_authorizer" "charlesmbrady_api_cognito_authorizer" {
  name                   = local.cognitoAuthorizerName
  rest_api_id            = module.charlesmbrady_api.rest_api_id
  type                   = "COGNITO_USER_POOLS"
  provider_arns          = [aws_cognito_user_pool.charlesmbrady.arn]
}