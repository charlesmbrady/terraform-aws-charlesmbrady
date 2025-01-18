variable "environment" {
  type = string
}

variable "certificate_arn" {
  type = string
}

variable "domain_aliases" {
  type = list(string)
}

variable "projects" {
  type = list(string)
}

variable "hosted_zone_id" {
  type = string
}

variable "root_project_name_prefix" {
  type = string
}

variable "alias_name" {
  type = string
  
}

variable "lambda_edge_rewrite_arn" {
  description = "ARN of the Lambda@Edge function for rewriting URIs"
  type        = string
}
