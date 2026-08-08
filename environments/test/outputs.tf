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

output "comfyui_instance_id" {
  value = module.main.comfyui_instance_id
}

output "comfyui_instance_public_ip" {
  value = module.main.comfyui_instance_public_ip
}

output "comfyui_ssm_shell_command" {
  value = module.main.comfyui_ssm_shell_command
}
