module "charlesmbrady" {
  source  = "charlava.scalr.io/charlava/cloudfront-module/aws"
  version = "3.0.0"

  # Preserve the country list from the former local module.
  locations = ["US", "CA", "GB", "AU", "NZ", "IE"]

  environment              = var.environment_tag
  certificate_arn          = var.certificate_arn
  domain_aliases           = var.domain_aliases
  hosted_zone_id           = var.hosted_zone_id
  root_project_name_prefix = var.root_project_name_prefix
  alias_name               = var.alias_name

}


module "mockdat" {
  source  = "charlava.scalr.io/charlava/cloudfront-module/aws"
  version = "3.0.0"

  # Preserve the country list from the former local module.
  locations = ["US", "CA", "GB", "AU", "NZ", "IE"]

  environment              = var.environment_tag
  certificate_arn          = var.certificate_arn
  domain_aliases           = var.mockdat_domain_aliases
  hosted_zone_id           = var.hosted_zone_id
  root_project_name_prefix = var.mockdat_root_project_name_prefix
  alias_name               = var.mockdat_alias_name
}

module "apps" {
  source  = "charlava.scalr.io/charlava/cloudfront-module/aws"
  version = "3.0.0"

  # Preserve the country list from the former local module.
  locations = ["US", "CA", "GB", "AU", "NZ", "IE"]

  environment              = var.environment_tag
  certificate_arn          = var.certificate_arn
  domain_aliases           = var.apps_domain_aliases
  hosted_zone_id           = var.hosted_zone_id
  root_project_name_prefix = var.apps_root_project_name_prefix
  alias_name               = var.apps_alias_name
}