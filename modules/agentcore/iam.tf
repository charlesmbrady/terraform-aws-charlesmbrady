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
      type = "Service"
      identifiers = [
        "bedrock.amazonaws.com"
      ]
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
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

  # Allow CloudWatch Logs
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/bedrock/agentcore/*"
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
