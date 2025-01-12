###############################################################################
#### Terraform Configuration
###############################################################################

resource "aws_iam_policy" "permissions_boundary" {
  name        = "PermissionsBoundaryPolicy"
  description = "Permissions boundary policy for managing IAM, Lambda, KMS, API Gateway, CloudFront, EC2, and other services"

  policy = file("../../iam_policies/permissions_boundary.json")
}
