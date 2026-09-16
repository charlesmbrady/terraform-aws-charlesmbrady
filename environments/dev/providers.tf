
# Configure the AWS Provider
provider "aws" {
  alias = "primary"

  allowed_account_ids = [
    var.account_id
  ]
}

terraform {
  backend "remote" {
    hostname     = "charlava.scalr.io"
    organization = "env-v0pdijhqh4b82lrpc"

    workspaces {
      name = "terraform-aws-charlesmbrady--dev"
    }
  }
}