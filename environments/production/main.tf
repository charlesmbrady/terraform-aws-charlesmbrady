###############################################################################
####     ██████╗ ██████╗  ██████╗ ██████╗
####     ██╔══██╗██╔══██╗██╔═══██╗██╔══██╗
####     ██████╔╝██████╔╝██║   ██║██║  ██║
####     ██╔═══╝ ██╔══██╗██║   ██║██║  ██║
####     ██║     ██║  ██║╚██████╔╝██████╔╝
####     ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═════╝
###############################################################################

locals{
  mockdat_domain = "https://mockdat.charlesmbrady.com"
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
  labs_domain = "https://labs.charlesmbrady.com"
  labs_domain_default_variants = [
    "${local.labs_domain}",
    "${local.labs_domain}/",
    "${local.labs_domain}/dashboard"
  ]
  labs_domain_logout_urls = [
    "${local.labs_domain}",
    "${local.labs_domain}/",
    "${local.labs_domain}/logout"
  ]
}
###############################################################################
module "main" {
  # FIXME: Use the correct name to pin down the source main module
  # source  = "app.terraform.io/charlesmbrady/"
  # version = "0.0.1"
  source = "../../"

  providers = {
    aws = aws.primary
  }

  kms_key_id = "arn:aws:kms:us-east-1:632785536297:key/fd098854-749f-488e-8cb3-1248c0479054"
  environment_tag = "Production"
  rsa_decrypt_key_b64 = var.rsa_decrypt_key_prod_b64

  root_project_name_prefix = "charlesmbrady"

  certificate_arn = "arn:aws:acm:us-east-1:632785536297:certificate/3ca27788-124e-425b-9606-815b81d3326c"
  domain_aliases = ["charlesmbrady.com"]
  hosted_zone_id = data.aws_route53_zone.main_zone.id
  alias_name = "charlesmbrady.com"

  mockdat_alias_name = "mockdat.charlesmbrady.com"
  mockdat_domain_aliases = ["mockdat.charlesmbrady.com"]
  mockdat_root_project_name_prefix = "mockdat"

  labs_alias_name = "labs.charlesmbrady.com"
  labs_domain_aliases = ["labs.charlesmbrady.com"]
  labs_root_project_name_prefix = "labs"

# # /* ------------------------------ Services API ------------------------------ */
  charlesmbrady_api_name = "charlesmbrady-services-prod"
  charlesmbrady_api_domain_name = "api.charlesmbrady.com"
  charlesmbrady_api_stage_name = "prod"
  charlesmbrady_api_throttling_rate_limit = 5
  charlesmbrady_api_throttling_burst_limit = 10
  charlesmbrady_api_metrics_enabled = false
  charlesmbrady_api_logging_level = "OFF"

  # # /* ------------------------------ Cognito User Pool ------------------------------ */
  cognito_user_pool_name = "charlesmbrady-prod"
  sso_domain_name = "auth.charlesmbrady.com"
  
  charlesmbrady_middleware_environment_variables = {
    EXAMPLE_ENV_VAR = "example"
  }

  cognito_clients_allowed_oauth_flows = ["code"]
  cognito_clients_allowed_oauth_flows_user_pool_client = true
  cognito_clients_allowed_oauth_scopes = ["email", "openid", "profile", "aws.cognito.signin.user.admin"]
  cognito_clients_supported_identity_providers = ["COGNITO"]

  cognito_client_mockdat_callback_urls = concat(
    local.mockdat_domain_default_variants
  )
  cognito_client_mockdat_default_redirect_uri = local.mockdat_domain
  cognito_client_mockdat_logout_urls = concat(
    local.mockdat_domain_logout_urls
  )
  cognito_client_labs_callback_urls = concat(
    local.labs_domain_default_variants
  )
  cognito_client_labs_default_redirect_uri = local.labs_domain
  cognito_client_labs_logout_urls = concat(
    local.labs_domain_logout_urls
  )
}
