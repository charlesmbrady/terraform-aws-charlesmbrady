terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.42.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4.0"
    }
  }
  required_version = ">= 1.0.0"
}
