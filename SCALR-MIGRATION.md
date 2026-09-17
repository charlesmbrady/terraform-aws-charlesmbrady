# Scalr workflow

This repository uses `main` for the active Scalr workspaces. Use OpenTofu 1.12.5.

| Workspace | Working directory |
| --- | --- |
| terraform-aws-charlesmbrady--test | `environments/test` |
| terraform-aws-charlesmbrady--prod | `environments/production` |

Create a feature branch and a pull request against the default branch. Scalr
previews each affected workspace. Merging queues normal plans; applies require
manual confirmation. Shared files at the repository root and under `modules/`
must trigger every active environment.

The remote backend is `charlava.scalr.io`, environment
`env-v0pdijhqh4b82lrpc`. Terraform Cloud is retained only as a locked historical
backup. Do not initialize with `-migrate-state` or unlock the former TFC workspace.

The website and CodeBuild policy import blocks adopt existing settings during
the module upgrade and can remain after import. Review the entire plan before
applying: production/Charlava may still contain previously identified pending
changes unrelated to this workflow consolidation.

Dev workspaces are retired and locked. Their historical configurations remain
on archive branches and must not be merged into the active default branch.
