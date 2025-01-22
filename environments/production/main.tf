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

  kms_key_id = "3958293b-681c-4899-9afa-cdff086d1bf3"
  environment_tag = "Production"
  rsa_decrypt_key_b64 = var.rsa_decrypt_key_prod_b64

  root_project_name_prefix = "charlesmbrady"

  certificate_arn = "arn:aws:acm:us-east-1:632785536297:certificate/3ca27788-124e-425b-9606-815b81d3326c"
  domain_aliases = ["charlesmbrady.com", "auth.charlesmbrady.com", "api.charlesmbrady.com"]
  hosted_zone_id = data.aws_route53_zone.main_zone.id
  alias_name = "mockdat.charlesmbrady.com"

  mockdat_alias_name = "mockdat.charlesmbrady.com"
  mockdat_domain_aliases = ["mockdat.charlesmbrady.com"]
  mockdat_root_project_name_prefix = "mockdat"

# # /* ------------------------------ Services API ------------------------------ */
  charlesmbrady_api_name = "charlesmbrady-CharlesmbradyAPI-Test"
  charlesmbrady_api_domain_name = "api.charlesmbrady.com"
  charlesmbrady_api_stage_name = "prod"
  charlesmbrady_api_throttling_rate_limit = 5
  charlesmbrady_api_throttling_burst_limit = 10
  charlesmbrady_api_metrics_enabled = false
  charlesmbrady_api_logging_level = "OFF"

# # Cognito
  cognito_user_pool_name = "charlesmbrady-prod"
  sso_domain_name = "auth.charlesmbrady.com"
  
#   # /* --------------------------- Charlesmbrady Website --------------------------- */
#   charlesmbrady_website_domain_name = "charlesmbrady.com"

#   # /* ------------------------------ Services App ------------------------------ */
#   charlesmbrady_services_app_domain_name = "services.charlesmbrady.com"
  
  charlesmbrady_middleware_environment_variables = {
    EXAMPLE_ENV_VAR = "example"
  }

}



# terraform {
#   backend "s3" {
#     # Backend configuration for production state
#   }
# }

# variable "environment" {
#   default = "prod"
# }
# variable "certificate_arn" {
#   default = "arn:aws:acm:us-east-1:123456789012:certificate/your-prod-cert"
# }
# variable "domain_aliases" {
#   default = ["charlesmbrady.com", "auth.charlesmbrady.com", "api.charlesmbrady.com"]
# }
# variable "projects" {
#   default = ["portfolio/project1", "portfolio/project2"]
# }
# variable "hosted_zone_id" {
#   default = "ZXXXXXXXXXXXXXXXXX"  # Hosted Zone ID for charlesmbrady.com
# }

# module "cloudfront_setup" {
#   source = "../../modules/cloudfront_setup"

#   environment      = var.environment
#   certificate_arn  = var.certificate_arn
#   domain_aliases   = var.domain_aliases
#   projects         = var.projects
#   hosted_zone_id   = var.hosted_zone_id
# }
