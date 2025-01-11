# Charlesmbrady portfolio website
module "charlesmbrady_portfolio_site" {
  source  = "./modules/cloudfront/"

  domain_name         = var.charlesmbrady_website_domain_name
  is_external_domain  = false
  use_custom_domain   = true
  default_root_object = "index.html"
}