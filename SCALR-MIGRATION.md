# Scalr migration configuration

This branch is dedicated to `terraform-aws-charlesmbrady--prod`. Its Scalr working directory is
`environments/production`. The state was copied and fully compared with
the frozen Terraform Cloud source. Use OpenTofu 1.12.5.

Automatic runs and applies are disabled during cutover. Review the migration
validation plan before any apply; no infrastructure changes were applied by the
migration. Keep the original TFC workspace locked.

This branch preserves the configuration chosen for the migration. Other
environment directories in this historical checkout are not cut over by this
branch. Do not use them as active deployment roots.
