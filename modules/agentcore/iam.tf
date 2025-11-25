###############################################################################
#### AgentCore IAM Role and Policies
###############################################################################

locals {
  agentcore_role_name = "${var.project_name}-agentcore-${var.environment_tag}"
}

###############################################################################
#### IAM Role for AgentCore Runtime
###############################################################################

# Trust policy for AgentCore service
data "aws_iam_policy_document" "agentcore_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["bedrock-agentcore.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAM Role for AgentCore
resource "aws_iam_role" "agentcore_runtime" {
  name                 = local.agentcore_role_name
  assume_role_policy   = data.aws_iam_policy_document.agentcore_assume_role.json
  permissions_boundary = var.iam_permissions_boundary_policy_arn

  tags = {
    Name        = local.agentcore_role_name
    Environment = var.environment_tag
  }
}

###############################################################################
#### IAM Policy for AgentCore Runtime
###############################################################################

data "aws_iam_policy_document" "agentcore_runtime_policy" {
  # Allow invoking foundation models
  statement {
    sid    = "BedrockModelInvoke"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream"
    ]
    resources = [
      "arn:aws:bedrock:${var.region}::foundation-model/*"
    ]
  }

  # AWS Marketplace permissions for Anthropic model access
  statement {
    sid    = "MarketplaceModelAccess"
    effect = "Allow"
    actions = [
      "aws-marketplace:ViewSubscriptions",
      "aws-marketplace:Subscribe"
    ]
    resources = ["*"]
  }

  # Allow invoking tool Lambda functions
  statement {
    sid    = "InvokeLambdaTools"
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      var.tool_lambda_arn
    ]
  }

  # Allow reading/writing to memory DynamoDB table
  statement {
    sid    = "DynamoDBMemoryAccess"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = [
      aws_dynamodb_table.agentcore_memory.arn,
      "${aws_dynamodb_table.agentcore_memory.arn}/index/*"
    ]
  }

  # Allow CloudWatch Logs for AgentCore runtimes (path from workshop)
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    # Broad grant; runtime creates dynamic log groups/streams. Narrowing can be done later.
    resources = ["*"]
  }

  # Observability (X-Ray tracing)
  statement {
    sid    = "XRayTracing"
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets"
    ]
    resources = ["*"]
  }

  # Metrics publishing with namespace condition
  statement {
    sid    = "CloudWatchMetrics"
    effect = "Allow"
    actions = ["cloudwatch:PutMetricData"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["bedrock-agentcore"]
    }
  }

  # Workload access token retrieval
  statement {
    sid    = "WorkloadAccessToken"
    effect = "Allow"
    actions = [
      "bedrock-agentcore:GetWorkloadAccessToken",
      "bedrock-agentcore:GetWorkloadAccessTokenForJWT",
      "bedrock-agentcore:GetWorkloadAccessTokenForUserId"
    ]
    resources = [
      "arn:aws:bedrock-agentcore:${var.region}:${var.account_id}:workload-identity-directory/default",
      "arn:aws:bedrock-agentcore:${var.region}:${var.account_id}:workload-identity-directory/default/workload-identity/*"
    ]
  }

  # Allow KMS encryption/decryption
  statement {
    sid    = "KMSAccess"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [var.kms_key_id]
  }

  # Allow S3 access to RAG embeddings bucket (conditional)
  dynamic "statement" {
    for_each = var.rag_enabled ? [1] : []
    content {
      sid    = "RagEmbeddingsS3Access"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      resources = [
        aws_s3_bucket.rag_embeddings[0].arn,
        "${aws_s3_bucket.rag_embeddings[0].arn}/*"
      ]
    }
  }

}

resource "aws_iam_policy" "agentcore_runtime" {
  name        = "${local.agentcore_role_name}-policy"
  description = "Policy for AgentCore runtime execution"
  policy      = data.aws_iam_policy_document.agentcore_runtime_policy.json
}

resource "aws_iam_role_policy_attachment" "agentcore_runtime" {
  role       = aws_iam_role.agentcore_runtime.name
  policy_arn = aws_iam_policy.agentcore_runtime.arn
}
