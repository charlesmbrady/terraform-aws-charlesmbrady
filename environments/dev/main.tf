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
  services_api_name = "ServicesAPI-Dev"
  services_api_domain_name = "services-dev.charlesmbrady.com"
  services_api_stage_name = "dev"
  services_api_throttling_rate_limit = 5
  services_api_throttling_burst_limit = 10
  services_api_metrics_enabled = false
  services_api_logging_level = "OFF"

  # /* ------------------------------ Cognito User Pool ------------------------------ */
  cognito_user_pool_name = "charlesmbrady-dev"
  
  # /* --------------------------- Charlesmbrady Website --------------------------- */
  charlesmbrady_website_domain_name = "dev.charlesmbrady.com"

  # /* ------------------------------ Services App ------------------------------ */
  charlesmbrady_services_app_domain_name = "services-dev.charlesmbrady.com"
  
  services_middleware_environment_variables = {
    EXAMPLE_ENV_VAR = "example"
  }

  services_middleware_secrets = {
    EXAMPLE_ENV_VAR = {
      encrypted_b64 = ["JcFY5WNZoZgfav1njFp++jREXW1HO1zRsgV/CtxRtT1HlkyGbfx5J7nCR2WTTJQsuk6t+n+koCK/rvJm41oAg8mHckOeImUi6aJR62Pq1VGKm5ofwiVADQvsqcdwAX3hmrl3GvGAGDw2N9VlkMKTSRMpizfwKNK4nP7Wq6cu832diJz14FossxsYqcRzIAOdnhuacO4gB8bb/Ar9lROB7NTi+KY+3akmNlXNlX3EmzgerKyXloo8KaF3TnDNQ00cpRb3pfud9tIGsRGJ3toGFRiOH5d3f2a5X0ddz6d8Qrj33HzeNcAsHOeRKTLanPRtA19d8GBBJ+svLN5Hh5kM2WXucbXpo9J7EHsVAzpuQu5ALmwarq0fKurTSgfUU+6DIrFO5duaLgAO22lT8kNHrdihkbhtTfhHDxqV2WyDJS2AD2S9dFNL1Hcp7B5Qj6VvEgEP+HaLxmrosir1OSmCg45mS6GYJ9LUv3DndAxcKgSFVwNh/uN74oVivPhYRyRVApx78nRokGB0WNBYnQGnJ05jOy0sYNjKsa57gK7W4lTSymdQeANutXmcnzATq6hO7tdxhtf6AkUlI0fw2MAZ2eAbiIUsHUigx3lA525aPSTQay++i+wbdM0dTpDtUz/ojtQ1sMEupcnILK1x6k1+hyieJSxSjY8wuDhCpE5YHW4="]
    }
  }



}