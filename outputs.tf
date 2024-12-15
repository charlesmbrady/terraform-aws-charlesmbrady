###############################################################################
#### Outputs
#### Define your module attributes, aka outputs.
###############################################################################

output "account_id" {
  value = data.aws_caller_identity.main.account_id
}

output "region" {
  value = data.aws_region.main.name
}

output "availability_zone_primary_name" {
  value = data.aws_availability_zone.primary.name
}