###############################################################################
#### Data Sources
#### Lookup information on pre-existing resources, such as our VPC.
###############################################################################

# FIXME: should this JUST be a var?
data "aws_kms_key" "master" {
  key_id = var.kms_key_id
}

###############################################################################
## Account and Identity
###############################################################################

# Retrieve information about the currently logged in user and account.
data "aws_caller_identity" "main" {
}

###############################################################################
## VPC and Subnets
###############################################################################

# Find our VPC. Assumes only one.
data "aws_vpc" "main" {
}

###############################################################################
## Availability Zone and Region
###############################################################################

# Find the current region
data "aws_region" "main" {
}

# Find the primary availability zone
data "aws_availability_zone" "primary" {
  zone_id = var.primary_az_id
}

###############################################################################
## Route 53
###############################################################################

# TODO: could remove this datasource, update the output of the cloudfront module to user the actually hosted zone id output instead of cloudfronts native one which causes issues
# # Find the hosted zone for the domain
# data "aws_route53_zone" "charlesmbrady_services" {
#   name = var.charlesmbrady_services_app_domain_name
# }

###############################################################################
## GITHUB OIDC provider
###############################################################################
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

###############################################################################
## permissions boundary
###############################################################################
data "aws_iam_policy" "role_permissions_boundary" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}