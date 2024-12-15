###############################################################################
####     ████████╗███████╗███████╗████████╗
####     ╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝
####        ██║   █████╗  ███████╗   ██║
####        ██║   ██╔══╝  ╚════██║   ██║
####        ██║   ███████╗███████║   ██║
####        ╚═╝   ╚══════╝╚══════╝   ╚═╝
###############################################################################

module "main" {
  # FIXME: Use the correct workspace name for your module.
  # source  = "app.terraform.io/charlesmbrady/template/aws"
  # version = "0.0.1"
  source = "../../"

  providers = {
    aws = aws.primary
  }

  # Environment and naming
  kms_key_id = ""
  environment_tag = "Test"
  # rsa_decrypt_key_b64 = var.rsa_decrypt_key_b64 #FIXME: Uncomment this line once key is added to the environment workspace

  # /* ------------------------------ Services API ------------------------------ */
  services_api_name = "ServicesAPI-Test"
  services_api_domain_name = "services-test.charlesmbrady.com"
  services_api_stage_name = "test"
  services_api_throttling_rate_limit = 5
  services_api_throttling_burst_limit = 10
  services_api_metrics_enabled = false
  services_api_logging_level = "OFF"

  # /* ------------------------------ Cognito User Pool ------------------------------ */
  cognito_user_pool_name = "charlesmbrady-test"

  # /* --------------------------- Charlesmbrady Website --------------------------- */
  charlesmbrady_website_domain_name = "test.charlesmbrady.com"

  # /* ------------------------------ Services App ------------------------------ */
  charlesmbrady_services_app_domain_name = "services-test.charlesmbrady.com"
  
  # services_middleware_environment_variables = {
  #   EXAMPLE_ENV_VAR = "example"
  # }
  # services_middleware_secrets = {
  #   EXAMPLE_ENV_VAR = {
  #     encrypted_b64 = ["as;dlkfjasldkfjasdflkj=="]
  #   }
  # }

}