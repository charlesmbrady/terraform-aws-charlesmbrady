###############################################################################
#### DynamoDB Table for AgentCore Memory Storage
###############################################################################

locals {
  memory_table_name = "${var.project_name}-agentcore-memory-${var.environment_tag}"
}

resource "aws_dynamodb_table" "agentcore_memory" {
  name         = local.memory_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "session_id"
  range_key    = "timestamp"

  server_side_encryption {
    enabled = false
  }

  point_in_time_recovery {
    enabled = false
  }

  # TTL for automatic cleanup of old conversations
  ttl {
    attribute_name = "expiration_time"
    enabled        = true
  }

  # GSI for querying by user ID
  global_secondary_index {
    name            = "user-index"
    hash_key        = "user_id"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  # GSI for querying by conversation type
  global_secondary_index {
    name            = "conversation-type-index"
    hash_key        = "conversation_type"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  # Required attributes for keys and GSIs
  attribute {
    name = "session_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "conversation_type"
    type = "S"
  }

  tags = {
    Name        = local.memory_table_name
    Environment = var.environment_tag
    Purpose     = "AgentCore conversation memory and history"
  }
}
