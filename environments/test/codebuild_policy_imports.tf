# Adopt the existing CodeBuild policy and preserve exclusive policy ownership.
import {
  to = module.main.module.agentcore.aws_iam_role_policy.codebuild
  id = "charlesmbrady-assistant-Test-cb-role:CodeBuildPolicy"
}

import {
  to = module.main.module.agentcore.aws_iam_role_policies_exclusive.codebuild
  id = "charlesmbrady-assistant-Test-cb-role"
}
