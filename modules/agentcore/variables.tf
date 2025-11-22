###############################################################################
#### AgentCore Module Variables
###############################################################################

variable "environment_tag" {
  type        = string
  description = "The environment tag (e.g., 'Test', 'Production')"
}

variable "project_name" {
  type        = string
  description = "The project name prefix for resource naming"
  default     = "charlesmbrady"
}

variable "kms_key_id" {
  type        = string
  description = "The ARN of the KMS key for encryption"
}

variable "iam_permissions_boundary_policy_arn" {
  type        = string
  description = "The ARN of the IAM permissions boundary policy"
}

variable "tool_lambda_arn" {
  type        = string
  description = "The ARN of the Lambda function to be used as an AgentCore tool"
}

variable "tool_lambda_name" {
  type        = string
  description = "The name of the Lambda function to be used as an AgentCore tool"
}

variable "region" {
  type        = string
  description = "AWS region for resource deployment"
}

variable "account_id" {
  type        = string
  description = "AWS account ID"
}

###############################################################################
#### AgentCore Configuration Variables
###############################################################################

variable "agent_name" {
  type        = string
  description = "Name for the AgentCore agent"
  default     = "charlesmbrady-assistant"
}

variable "agent_instruction" {
  type        = string
  description = "Instructions for the AgentCore agent behavior"
  default     = "You are a helpful assistant for the charlesmbrady.com platform. You can help users with their queries and provide information about available services."
}

variable "foundation_model" {
  type        = string
  description = "The foundation model ID to use for the agent (e.g., anthropic.claude-3-5-sonnet-20240620-v1:0)"
  default     = "anthropic.claude-3-5-sonnet-20240620-v1:0"
}

variable "enable_memory" {
  type        = bool
  description = "Whether to enable conversation memory for the agent"
  default     = true
}

variable "memory_retention_days" {
  type        = number
  description = "Number of days to retain conversation history"
  default     = 30
}

variable "agent_description" {
  type        = string
  description = "Description of the agent's purpose"
  default     = "AI assistant for the charlesmbrady.com platform"
}

###############################################################################
#### DIY RAG Configuration (Lightweight Retrieval Augmentation)
###############################################################################

variable "rag_enabled" {
  type        = bool
  description = "Whether to enable lightweight DIY RAG (S3 stored embeddings)"
  default     = true
}

variable "rag_bucket_name" {
  type        = string
  description = "Optional override for the S3 bucket name used to store embeddings JSON. If empty, a name will be derived."
  default     = ""
}

