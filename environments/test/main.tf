###############################################################################
####     ████████╗███████╗███████╗████████╗
####     ╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝
####        ██║   █████╗  ███████╗   ██║
####        ██║   ██╔══╝  ╚════██║   ██║
####        ██║   ███████╗███████║   ██║
####        ╚═╝   ╚══════╝╚══════╝   ╚═╝
###############################################################################

locals {
  local_web_domain = "http://localhost:3000"
  local_web_domain_default_variants = [
    "${local.local_web_domain}",
    "${local.local_web_domain}/",
    "${local.local_web_domain}/dashboard"
  ]
  local_web_domain_logout_urls = [
    "${local.local_web_domain}",
    "${local.local_web_domain}/",
    "${local.local_web_domain}/logout"
  ]
  mockdat_domain = "https://mockdat-test.charlesmbrady.com"
  mockdat_domain_default_variants = [
    "${local.mockdat_domain}",
    "${local.mockdat_domain}/",
    "${local.mockdat_domain}/dashboard"
  ]
  mockdat_domain_logout_urls = [
    "${local.mockdat_domain}",
    "${local.mockdat_domain}/",
    "${local.mockdat_domain}/logout"
  ]
  apps_domain = "https://apps-test.charlesmbrady.com"
  apps_domain_default_variants = [
    "${local.apps_domain}",
    "${local.apps_domain}/",
    "${local.apps_domain}/dashboard"
  ]
  apps_domain_logout_urls = [
    "${local.apps_domain}",
    "${local.apps_domain}/",
    "${local.apps_domain}/logout"
  ]
}

module "main" {
  source = "../../"

  providers = {
    aws = aws.primary
  }

  # Environment and naming
  kms_key_id               = "arn:aws:kms:us-east-1:632785536297:key/fd098854-749f-488e-8cb3-1248c0479054"
  environment_tag          = "Test"
  rsa_decrypt_key_b64      = var.rsa_decrypt_key_test_b64
  root_project_name_prefix = "charlesmbrady"

  certificate_arn = "arn:aws:acm:us-east-1:632785536297:certificate/3ca27788-124e-425b-9606-815b81d3326c"
  domain_aliases  = ["test.charlesmbrady.com"]
  hosted_zone_id  = data.aws_route53_zone.main_zone.id
  alias_name      = "test.charlesmbrady.com"

  mockdat_alias_name               = "mockdat-test.charlesmbrady.com"
  mockdat_domain_aliases           = ["mockdat-test.charlesmbrady.com"]
  mockdat_root_project_name_prefix = "mockdat"

  apps_alias_name               = "apps-test.charlesmbrady.com"
  apps_domain_aliases           = ["apps-test.charlesmbrady.com"]
  apps_root_project_name_prefix = "apps"

  # /* ------------------------------ Services API ------------------------------ */
  charlesmbrady_api_name                   = "charlesmbrady-CharlesmbradyAPI-Test"
  charlesmbrady_api_domain_name            = "api-test.charlesmbrady.com"
  charlesmbrady_api_stage_name             = "test"
  charlesmbrady_api_throttling_rate_limit  = 5
  charlesmbrady_api_throttling_burst_limit = 10
  charlesmbrady_api_metrics_enabled        = false
  charlesmbrady_api_logging_level          = "OFF"


  # # /* ------------------------------ Cognito User Pool ------------------------------ */
  cognito_user_pool_name = "charlesmbrady-test"
  sso_domain_name        = "auth-test.charlesmbrady.com"

  charlesmbrady_middleware_environment_variables = {
    EXAMPLE_ENV_VAR = "example"
  }

  cognito_clients_allowed_oauth_flows                  = ["code"]
  cognito_clients_allowed_oauth_flows_user_pool_client = true
  cognito_clients_allowed_oauth_scopes                 = ["email", "openid", "profile", "aws.cognito.signin.user.admin"]
  cognito_clients_supported_identity_providers         = ["COGNITO"]

  cognito_client_mockdat_callback_urls = concat(
    local.local_web_domain_default_variants,
    local.mockdat_domain_default_variants
  )
  cognito_client_mockdat_default_redirect_uri = local.local_web_domain
  cognito_client_mockdat_logout_urls = concat(
    local.local_web_domain_logout_urls,
    local.mockdat_domain_logout_urls
  )
  cognito_client_apps_callback_urls = concat(
    local.local_web_domain_default_variants,
    local.apps_domain_default_variants
  )
  cognito_client_apps_default_redirect_uri = local.local_web_domain
  cognito_client_apps_logout_urls = concat(
    local.local_web_domain_logout_urls,
    local.apps_domain_logout_urls
  )


}
