###############################################################################
## Access and Credentials
###############################################################################
variable "assume_role_arn" {
  type        = string
  description = "The ARN of the role to assume."
  default     = null
}

variable "assume_role_external_id" {
  type        = string
  description = "An external id value to pass while assuming the AWS role."
  default     = null
}

variable "account_id" {
  type        = string
  description = "An AWS cli profile to use for authentication if running from a workstation."
}