
locals {
  mockdat_name           = "mockdat"
  self_driving_car_name  = "self-driving-car"
  cv_writer_name         = "cv-writer"
}

resource "aws_dynamodb_table" "mockdat" {
  name         = "${local.mockdat_name}-${var.environment_tag}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  server_side_encryption {
    enabled = false
  }

  point_in_time_recovery {
    enabled = false
  }

  # GSI for queries by visibility - to find all public scenarios
  global_secondary_index {
    name            = "visibility-index"
    hash_key        = "visibility"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  # GSI for queries by creator - so users can find their own scenarios
  global_secondary_index {
    name            = "creator-index"
    hash_key        = "creator_id"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  # Define required attributes
  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  attribute {
    name = "visibility"
    type = "S"
  }

  attribute {
    name = "creator_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  tags = {
    Name        = local.mockdat_name
    Environment = var.environment_tag
  }
}

resource "aws_dynamodb_table" "self_driving_car" {
  name         = "${local.self_driving_car_name}-${var.environment_tag}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  server_side_encryption {
    enabled = false
  }

  point_in_time_recovery {
    enabled = false
  }

  # GSI for queries by brain type
  global_secondary_index {
    name            = "brain-type-index"
    hash_key        = "brain_type"
    range_key       = "version"
    projection_type = "ALL"
  }

  # GSI for queries by creator
  global_secondary_index {
    name            = "creator-index"
    hash_key        = "creator_id"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  attribute {
    name = "brain_type"
    type = "S"
  }

  attribute {
    name = "version"
    type = "S"
  }

  attribute {
    name = "creator_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  tags = {
    Name        = local.self_driving_car_name
    Environment = var.environment_tag
  }
}

resource "aws_dynamodb_table" "cv_writer" {
  name         = "${local.cv_writer_name}-${var.environment_tag}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  server_side_encryption {
    enabled = false
  }

  point_in_time_recovery {
    enabled = false
  }

  # GSI for queries by user - users will only see their own items
  global_secondary_index {
    name            = "user-index"
    hash_key        = "user_id"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  # No need for document-type-index since users will only see their own items

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  tags = {
    Name        = local.cv_writer_name
    Environment = var.environment_tag
  }
}