###############################################################################
#### Outputs
#### Define your module attributes, aka outputs.
###############################################################################

output "account_id" {
  value = module.main.account_id
}

output "region" {
  value = module.main.region
}

output "availability_zone_primary_name" {
  value = module.main.availability_zone_primary_name
}
