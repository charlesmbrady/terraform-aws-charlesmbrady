###############################################################################
####     ██████╗ ██████╗  ██████╗ ██████╗
####     ██╔══██╗██╔══██╗██╔═══██╗██╔══██╗
####     ██████╔╝██████╔╝██║   ██║██║  ██║
####     ██╔═══╝ ██╔══██╗██║   ██║██║  ██║
####     ██║     ██║  ██║╚██████╔╝██████╔╝
####     ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═════╝
###############################################################################

module "main" {
  source = "../../"

  providers = {
    aws = aws.primary
  }

  kms_key_id = ""
  environment_tag = "Production"
  rsa_decrypt_key_b64 = var.rsa_decrypt_key_prod_b64

# /* ------------------------------ Services API ------------------------------ */
  services_api_name = "charlesmbrady-ServicesAPI-Prod"
  services_api_domain_name = "services.charlesmbrady.com"
  services_api_stage_name = "prod"
  services_api_throttling_rate_limit = 5
  services_api_throttling_burst_limit = 10
  services_api_metrics_enabled = false
  services_api_logging_level = "OFF"

# Cognito
  cognito_user_pool_name = "charlesmbrady"
  sso_domain_name = "auth.charlesmbrady.com"
  
  # /* --------------------------- Charlesmbrady Website --------------------------- */
  charlesmbrady_website_domain_name = "charlesmbrady.com"

  # /* ------------------------------ Services App ------------------------------ */
  charlesmbrady_services_app_domain_name = "services.charlesmbrady.com"
  
  services_middleware_environment_variables = {
    EXAMPLE_ENV_VAR = "example"
  }

}