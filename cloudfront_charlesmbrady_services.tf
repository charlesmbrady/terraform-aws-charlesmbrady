# Charlesmbrady services
module "charlesmbrady_services" {
  source  = "charlava.scalr.io/charlava/cloudfront-module/aws"
  version = "1.1.15"

  domain_name         = var.charlesmbrady_services_app_domain_name
  is_external_domain  = false
  use_custom_domain   = true
  default_root_object = "index.html"
}