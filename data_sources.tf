###############################################################################
#### Data Sources
#### Lookup information on pre-existing resources, such as our VPC.
###############################################################################

# FIXME: should this JUST be a var?
data "kms_key" "master" {
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