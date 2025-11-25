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
variable "cognito_user_pool_name" {
  type        = string
  description = "The name of the cognito user pool"
}


variable "cognito_clients_allowed_oauth_flows" {
  type        = list(string)
  description = "The allowed oauth flows for the cognito clients"
}
variable "cognito_clients_allowed_oauth_flows_user_pool_client" {
  type        = bool
  description = "Whether to allow the oauth flows for the cognito clients"
}
variable "cognito_clients_allowed_oauth_scopes" {
  type        = list(string)
  description = "The allowed oauth scopes for the cognito clients"
}
variable "cognito_clients_supported_identity_providers" {
  type        = list(string)
  description = "The supported identity providers for the cognito clients"
}

variable "cognito_client_mockdat_callback_urls" {
  type        = list(string)
  description = "The callback urls for the mockdat cognito client"
}
variable "cognito_client_mockdat_default_redirect_uri" {
  type        = string
  description = "The default redirect uri for the mockdat cognito client"
}
variable "cognito_client_mockdat_logout_urls" {
  type        = list(string)
  description = "The logout urls for the mockdat cognito client"
}

variable "cognito_client_apps_callback_urls" {
  type        = list(string)
  description = "The callback urls for the apps cognito client"
}
variable "cognito_client_apps_default_redirect_uri" {
  type        = string
  description = "The default redirect uri for the apps cognito client"
}
variable "cognito_client_apps_logout_urls" {
  type        = list(string)
  description = "The logout urls for the apps cognito client"
}

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

variable "charlesmbrady_api_name" {
  type        = string
  description = "The name of the 'charlesmbrady' apigateway endpoint"
}

variable "charlesmbrady_api_stage_name" {
  type        = string
  description = "The name of the 'charlesmbrady' apigateway stage"
}

variable "charlesmbrady_api_domain_name" {
  type        = string
  description = "The custom domain name for the 'charlesmbrady' apigateway endpoint"
}

variable "charlesmbrady_api_throttling_rate_limit" {
  type        = number
  description = "API Gateway total requests across all APIs within a REST endpoint"
}

variable "charlesmbrady_api_throttling_burst_limit" {
  type        = number
  description = "API Gateway total concurrent connections allowed for all APIs within a REST endpoint"
}

variable "charlesmbrady_api_metrics_enabled" {
  type        = bool
  description = "Enable detailed metrics for the API Gateway"
  default     = false
}

variable "charlesmbrady_api_logging_level" {
  type        = string
  description = "(Optional) Specifies the logging level for this method, which effects the log entries pushed to Amazon CloudWatch Logs. The available levels are OFF, ERROR, and INFO."
  default     = "OFF"
}

variable "charlesmbrady_middleware_environment_variables" {
  type        = map(any)
  description = "Environment variables for the charlesmbrady middleware lambda"
}

variable "sso_domain_name" {
  type        = string
  description = "The domain name for the SSO service"
}

variable "certificate_arn" {
  type        = string
  description = "The ARN of the ACM certificate to use for the custom domain"
}

variable "domain_aliases" {
  type        = list(string)
  description = "A list of domain aliases to use for the custom domain"
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
variable "mockdat_domain_aliases" {
  type = list(string)
}

variable "mockdat_root_project_name_prefix" {
  type = string
}

variable "mockdat_alias_name" {
  type = string
}

variable "apps_domain_aliases" {
  type = list(string)
}

variable "apps_root_project_name_prefix" {
  type = string
}

variable "apps_alias_name" {
  type = string
}

###############################################################################
#### AgentCore Configuration
###############################################################################

variable "agentcore_agent_name" {
  type        = string
  description = "Name for the AgentCore agent"
  default     = "assistant"
}

variable "agentcore_agent_instruction" {
  type        = string
  description = "Instructions for the AgentCore agent behavior"
  default     = "You are a helpful assistant for the charlesmbrady.com platform. You can help users with their queries and provide information about available services."
}

variable "agentcore_foundation_model" {
  type        = string
  description = "The foundation model ID to use for the agent"
  default     = "anthropic.claude-3-5-sonnet-20240620-v1:0"
}

variable "agentcore_enable_memory" {
  type        = bool
  description = "Whether to enable conversation memory for the agent"
  default     = true
}

variable "agentcore_memory_retention_days" {
  type        = number
  description = "Number of days to retain conversation history"
  default     = 30
}

variable "agentcore_agent_description" {
  type        = string
  description = "Description of the agent's purpose"
  default     = "AI assistant for the charlesmbrady.com platform"
}

###############################################################################
#### DIY RAG Configuration (Root)
###############################################################################

variable "agentcore_rag_enabled" {
  type        = bool
  description = "Whether to enable lightweight DIY RAG embeddings S3 bucket"
  default     = true
}

variable "agentcore_rag_bucket_name" {
  type        = string
  description = "Optional override for RAG embeddings S3 bucket name. Leave blank to auto-generate."
  default     = ""
}
