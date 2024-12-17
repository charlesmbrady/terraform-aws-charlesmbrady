
# Configure the AWS Provider
provider "aws" {
  alias = "primary"

  allowed_account_ids = [
    var.account_id
  ]
}

terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "charlava"

    workspaces {
      name = "terraform-aws-charlesmbrady--test"
    }
  }
}