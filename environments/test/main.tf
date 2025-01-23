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
  kms_key_id = "arn:aws:kms:us-east-1:632785536297:key/fd098854-749f-488e-8cb3-1248c0479054"
  environment_tag = "Test"
  rsa_decrypt_key_b64 = var.rsa_decrypt_key_test_b64
  root_project_name_prefix = "charlesmbrady"

  certificate_arn = "arn:aws:acm:us-east-1:632785536297:certificate/3ca27788-124e-425b-9606-815b81d3326c"
  domain_aliases = ["test.charlesmbrady.com"] #TODO: could this substitute for creating these resources elsewhere?
  hosted_zone_id = data.aws_route53_zone.main_zone.id
  alias_name = "test.charlesmbrady.com"

  mockdat_alias_name = "mockdat-test.charlesmbrady.com"
  mockdat_domain_aliases = ["mockdat-test.charlesmbrady.com"]
  mockdat_root_project_name_prefix = "mockdat"

  # /* ------------------------------ Services API ------------------------------ */
  charlesmbrady_api_name = "charlesmbrady-CharlesmbradyAPI-Test"
  charlesmbrady_api_domain_name = "api-test.charlesmbrady.com"
  charlesmbrady_api_stage_name = "test"
  charlesmbrady_api_throttling_rate_limit = 5
  charlesmbrady_api_throttling_burst_limit = 10
  charlesmbrady_api_metrics_enabled = false
  charlesmbrady_api_logging_level = "OFF"


  # # /* ------------------------------ Cognito User Pool ------------------------------ */
  cognito_user_pool_name = "charlesmbrady-test"
  sso_domain_name = "auth-test.charlesmbrady.com"

  # # /* --------------------------- Charlesmbrady Website --------------------------- */
  # charlesmbrady_website_domain_name = "test.charlesmbrady.com"

  # # /* ------------------------------ Services App ------------------------------ */
  # charlesmbrady_services_app_domain_name = "services-test.charlesmbrady.com"
  
  charlesmbrady_middleware_environment_variables = {
    EXAMPLE_ENV_VAR = "example"
  }

}


# variable "environment" {
#   default = "test"
# }
# variable "certificate_arn" {
#   default = "arn:aws:acm:us-east-1:123456789012:certificate/your-test-cert"
# }
# variable "domain_aliases" {
#   default = ["test.charlesmbrady.com", "auth-test.charlesmbrady.com", "api-test.charlesmbrady.com"]
# }
# variable "projects" {
#   default = ["portfolio/project1", "portfolio/project2"]
# }
# variable "hosted_zone_id" {
#   default = "ZXXXXXXXXXXXXXXXXX"  # Likely same zone ID since it's same root domain but subdomain records differ
# }

# module "cloudfront_setup" {
#   source = "../../modules/cloudfront_setup"

#   environment      = var.environment
#   certificate_arn  = var.certificate_arn
#   domain_aliases   = var.domain_aliases
#   projects         = var.projects
#   hosted_zone_id   = var.hosted_zone_id
# }
