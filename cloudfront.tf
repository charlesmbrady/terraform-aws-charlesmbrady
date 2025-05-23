module "charlesmbrady" {
  source = "./modules/cloudfront_setup"

  environment      = var.environment_tag
  certificate_arn  = var.certificate_arn
  domain_aliases   = var.domain_aliases
  hosted_zone_id   = var.hosted_zone_id
  root_project_name_prefix = var.root_project_name_prefix
  alias_name = var.alias_name

}


module "mockdat" {
  source = "./modules/cloudfront_setup"

  environment      = var.environment_tag
  certificate_arn  = var.certificate_arn
  domain_aliases   = var.mockdat_domain_aliases
  hosted_zone_id   = var.hosted_zone_id
  root_project_name_prefix = var.mockdat_root_project_name_prefix
  alias_name = var.mockdat_alias_name
}

module "labs" {
  source = "./modules/cloudfront_setup"

  environment      = var.environment_tag
  certificate_arn  = var.certificate_arn
  domain_aliases   = var.labs_domain_aliases
  hosted_zone_id   = var.hosted_zone_id
  root_project_name_prefix = var.labs_root_project_name_prefix
  alias_name = var.labs_alias_name
}