module "services_api" {
  source  = "app.terraform.io/charlava/apigw-module/aws"
  version = "1.2.0"

  api_name       = var.services_api_name
  api_stage_name = var.services_api_stage_name
  api_throttling_rate_limit = var.services_api_throttling_rate_limit
  api_throttling_burst_limit = var.services_api_throttling_burst_limit
  api_metrics_enabled = var.services_api_metrics_enabled
  api_logging_level = var.services_api_logging_level
  create_api_key = true
  role_permissions_boundary_policy_name = "AdministratorAccess" #TODO: Replace with more restrictive

  api_template = file("../../api_services.yml")
  api_template_vars = {
    services_api_domain_name = var.services_api_domain_name
    cognito_user_pool_arn = aws_cognito_user_pool.charlesmbrady.arn
    lambda_services_middleware_arn = module.services_middleware_lambda.function_arn
    region = data.aws_region.main.name
  }
}

# Cognito Authorizer
resource "aws_api_gateway_authorizer" "services_api_cognito_authorizer" {
  name                   = "CognitoUserPoolAuthorizer"
  rest_api_id            = module.services_api.api_gateway_id
  type                   = "COGNITO_USER_POOLS"
  provider_arns          = [aws_cognito_user_pool_domain.charlesmbrady.arn]
}