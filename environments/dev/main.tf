###############################################################################
####      ██████╗ ███████╗██╗   ██╗
####      ██╔══██╗██╔════╝██║   ██║
####      ██║  ██║█████╗  ██║   ██║
####      ██║  ██║██╔══╝  ╚██╗ ██╔╝
####      ██████╔╝███████╗ ╚████╔╝ 
####      ╚═════╝ ╚══════╝  ╚═══╝  
###############################################################################

module "main" {
  source = "../../"

  providers = {
    aws = aws.primary
  }

  # Environment and naming
  kms_key_id = "fd098854-749f-488e-8cb3-1248c0479054"
  environment_tag = "Dev"
  rsa_decrypt_key_b64 = var.rsa_decrypt_key_b64

  # /* ------------------------------ Services API ------------------------------ */
  services_api_name = "charlesmbrady-ServicesAPI-Dev"
  services_api_domain_name = "services-dev.charlesmbrady.com"
  services_api_stage_name = "dev"
  services_api_throttling_rate_limit = 5
  services_api_throttling_burst_limit = 10
  services_api_metrics_enabled = false
  services_api_logging_level = "OFF"

  # /* ------------------------------ Cognito User Pool ------------------------------ */
  cognito_user_pool_name = "charlesmbrady-dev"
  sso_domain_name = "auth-dev.charlesmbrady.com"
  
  # /* --------------------------- Charlesmbrady Website --------------------------- */
  charlesmbrady_website_domain_name = "dev.charlesmbrady.com"

  # /* ------------------------------ Services App ------------------------------ */
  charlesmbrady_services_app_domain_name = "services-dev.charlesmbrady.com"
  
  services_middleware_environment_variables = {
    EXAMPLE_ENV_VAR = "example"
  }

}