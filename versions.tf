
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.22.1"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
  }
  required_version = ">= 1.0.0"
}
