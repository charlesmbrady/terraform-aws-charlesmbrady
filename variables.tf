###############################################################################
#### Variables
#### Define your module arguments, aka variables.
###############################################################################
variable "kms_key_id" {
  type        = string
  description = "The id of the KMS key to use for encryption."
}

variable "rsa_decrypt_key_b64" {
  type        = string
  description = "The base64 encoded private key to use for decryption."
}
###############################################################################
## Regions and Availability zones
###############################################################################

variable "primary_az_id" {
  type        = string
  description = "The primary availability zone is the az in which resources should be first build. For highly available applications, use the primary az in conjunction with the secondary az."
  default     = "use1-az4"
}

variable "secondary_az_id" {
  type        = string
  description = "The secondary availability zone is the az which redundant resources should be created. For highly available applications, use the secondary az in conjunction with the primary az."
  default     = "use1-az6"
}

variable "tertiary_az_id" {
  type        = string
  description = "The tertiary availability zone is the az which redundant resources necessary for quorum, tiebreak, or consensus should be created. Use the tertiary az in conjunction with the primary and secondary azs."
  default     = "use1-az1"
}

###############################################################################
#### Tagging and Naming
###############################################################################

variable "environment_tag" {
  type        = string
  description = "The name of the environment to tag resources"
}

variable "name_prefix" {
  type        = string
  default     = "Charlesmbrady"
  description = "A prefix to use for naming resources."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources that support them."
}

# ###############################################################################

# variable "charlesmbrady_website_domain_name" {
#   type        = string
#   description = "The domain name for the website (can be a root domain or subdomain or a multilevel subdomain)"
# }

# locals {
#   tags = merge({
#     "Name" : var.name_prefix
#     "Environment" : var.environment_tag
#     },
#     var.tags
#   )
# }

# ###############################################################################
# #### Cognito User Pool
# ###############################################################################
# variable "cognito_user_pool_name" {
#   type        = string
#   description = "The name of the cognito user pool"
# }

# # /* -------------------------------------------------------------------------- */
# # /*                                Services App                                */
# # /* -------------------------------------------------------------------------- */
# variable "charlesmbrady_services_app_domain_name" {
#   type        = string
#   description = "The name of the services app services.charlesmbrady.com or services-dev.charlesmbrady.com for example"
# }

# ###############################################################################
# #### Servies API
# ###############################################################################

# variable "services_api_name" {
#   type        = string
#   description = "The name of the 'services' apigateway endpoint"
# }

# variable "services_api_stage_name" {
#   type        = string
#   description = "The name of the 'services' apigateway stage"
# }

# variable "services_api_domain_name" {
#   type        = string
#   description = "The custom domain name for the 'services' apigateway endpoint"
# }

# variable "services_api_throttling_rate_limit" {
#   type        = number
#   description = "API Gateway total requests across all APIs within a REST endpoint"
# }

# variable "services_api_throttling_burst_limit" {
#   type        = number
#   description = "API Gateway total concurrent connections allowed for all APIs within a REST endpoint"
# }

# variable "services_api_metrics_enabled" {
#   type        = bool
#   description = "Enable detailed metrics for the API Gateway"
#   default    = false
# }

# variable "services_api_logging_level" {
#   type        = string
#   description = "(Optional) Specifies the logging level for this method, which effects the log entries pushed to Amazon CloudWatch Logs. The available levels are OFF, ERROR, and INFO."
#   default     = "OFF"
# }

# variable "services_middleware_environment_variables" {
#   type        = map(any)
#   description = "Environment variables for the services middleware lambda"
# }

# variable "sso_domain_name" {
#   type        = string
#   description = "The domain name for the SSO service"
# }

variable "certificate_arn" {
  type        = string
  description = "The ARN of the ACM certificate to use for the custom domain"
}

variable "domain_aliases" {
  type        = list(string)
  description = "A list of domain aliases to use for the custom domain"
}

variable "projects" {
  type        = list(string)
  description = "A list of projects to use for the custom domain"
}

variable "hosted_zone_id" {
  type        = string
  description = "The hosted zone id for the custom domain"
}

variable "root_project_name_prefix" {
  type        = string
  description = "The root project name prefix"
}

variable "alias_name" {
  type        = string
  description = "The alias name for the custom domain"
}

variable "lambda_edge_rewrite_arn" {
  description = "ARN of the Lambda@Edge function for rewriting URIs"
  type        = string
  default     = "arn:aws:lambda:us-east-1:632785536297:function:portfolio_rewrite_edge:1"  // Provide a default or require it from caller
}
