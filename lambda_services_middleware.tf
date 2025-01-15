# locals {
#   services_middleware_app_base_name = "services-middleware"
#   services_middleware_name     = "charlesmbrady_${var.environment_tag}_services_middleware"
#   services_middleware_app_name = "charlesmbrady-${var.environment_tag}-services-middleware"
# }

# module "services_middleware_lambda" {
#   source  = "app.terraform.io/charlava/lambda-module/aws"
#   version = "1.2.8"


#   name     = local.services_middleware_name
#   app_name = local.services_middleware_app_name
#   handler  = "${local.services_middleware_app_base_name}/main.handler"

#   iam_permissions_boundary_policy_arn = data.aws_iam_policy.role_permissions_boundary.arn
#   cloudwatch_log_kms_key_arn          = data.aws_kms_key.master.arn
#   vpc_id                              = null
#   subnet_ids                          = []
#   attach_to_vpc                       = false
#   create_with_stub                    = true
#   create_api_gateway_integration      = true
#   api_gateway_rest_api_id             = module.services_api.rest_api_id
#   role_arn                            = module.services_middleware_iam.role_arn
#   role_name                           = module.services_middleware_iam.role_name
#   oidc_provider_arn                   = data.aws_iam_openid_connect_provider.github.arn
#   environment_tag                     = var.environment_tag
#   runtime                             = "nodejs20.x"
#   timeout                             = 900 # use whole 15m

#   environment_variables = merge(
#     var.services_middleware_environment_variables
#   )
# }

# module "services_middleware_iam" {
#   source  = "app.terraform.io/charlava/iam-module/aws"
#   version = "1.1.0"

#   iam_permissions_boundary_policy_arn = data.aws_iam_policy.role_permissions_boundary.arn

#   role_name          = "${local.services_middleware_app_name}-role"
#   policy_name        = "${local.services_middleware_app_name}-policy"
#   assume_role_policy = file("../../iam_policies/lambda_assume_role.json")
#   template           = file("../../iam_policies/lambda_common.json")

#   role_vars = {
#     kms_key_id     = data.aws_kms_key.master.arn
#   }
# }
