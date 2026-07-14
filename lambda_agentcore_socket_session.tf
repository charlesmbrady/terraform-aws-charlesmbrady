locals {
  agentcore_socket_session_app_name = "agentcore-socket-session"
  agentcore_socket_session_name     = "charlesmbrady_agentcore_socket_session_${var.environment_tag}"
}

module "agentcore_socket_session_lambda" {
  source  = "app.terraform.io/charlava/lambda-module/aws"
  version = "1.2.8"

  name     = local.agentcore_socket_session_name
  app_name = local.agentcore_socket_session_app_name
  handler  = "${local.agentcore_socket_session_app_name}/main.handler"

  iam_permissions_boundary_policy_arn = data.aws_iam_policy.role_permissions_boundary.arn
  cloudwatch_log_kms_key_arn          = var.kms_key_id
  vpc_id                              = null
  subnet_ids                          = []
  attach_to_vpc                       = false
  create_with_stub                    = true
  create_api_gateway_integration      = true
  api_gateway_rest_api_id             = module.charlesmbrady_api.rest_api_id
  role_arn                            = module.agentcore_socket_session_iam.role_arn
  role_name                           = module.agentcore_socket_session_iam.role_name
  oidc_provider_arn                   = data.aws_iam_openid_connect_provider.github.arn
  environment_tag                     = var.environment_tag
  runtime                             = "nodejs20.x"
  timeout                             = 10
  memory_size                         = 256

  environment_variables = {
    ENABLED               = tostring(var.agentcore_socket_enabled)
    ALLOWED_ORIGINS       = join(",", var.agentcore_socket_allowed_origins)
    QUOTA_TABLE_NAME      = aws_dynamodb_table.agentcore_socket_quota.name
    HOURLY_IP_LIMIT       = tostring(var.agentcore_socket_hourly_ip_limit)
    DAILY_TEXT_LIMIT      = tostring(var.agentcore_socket_daily_text_limit)
    IP_HASH_SALT          = "${var.root_project_name_prefix}-${var.environment_tag}"
    URL_EXPIRES_SECONDS   = "60"
    AGENTCORE_RUNTIME_ARN = module.agentcore.runtime_arn
  }
}

module "agentcore_socket_session_iam" {
  source  = "app.terraform.io/charlava/iam-module/aws"
  version = "1.2.0"

  iam_permissions_boundary_policy_arn = data.aws_iam_policy.role_permissions_boundary.arn

  role_name          = "${local.agentcore_socket_session_app_name}-${var.environment_tag}-role"
  policy_name        = "${local.agentcore_socket_session_app_name}-${var.environment_tag}-policy"
  assume_role_policy = "../../iam_policies/lambda_assume_role.json"
  template           = "../../iam_policies/lambda_agentcore_socket_session.json"

  role_vars = {
    kms_key_id            = var.kms_key_id
    quota_table_arn       = aws_dynamodb_table.agentcore_socket_quota.arn
    agentcore_runtime_arn = module.agentcore.runtime_arn
  }
}