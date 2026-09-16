# Scalr migration configuration

This branch is dedicated to `terraform-aws-charlesmbrady--dev`. Its Scalr working directory is
`environments/dev`. The state was copied and fully compared with
the frozen Terraform Cloud source. Use OpenTofu 1.12.5.

Automatic runs and applies are disabled during cutover. Review the migration
validation plan before any apply; no infrastructure changes were applied by the
migration. Keep the original TFC workspace locked.

This dev environment was previously being destroyed. Its state is preserved
for archival and cleanup; do not run a normal apply to recreate it. The Scalr
workspace remains locked after the plan-only inspection.
