locals {
  mockdat_name           = "mockdat"
  # self_driving_car_name  = "self-driving-car"
  # google_books_search_name = "google-books-search"
  # scrape_n_surf_name     = "scrape-n-surf"
  # dupe_gen_name          = "dupe-gen"
  # better_banking_name    = "better-banking"
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

# resource "aws_dynamodb_table" "self_driving_car" {
#   name         = "${local.self_driving_car_name}-${var.environment_tag}"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "pk"
#   range_key    = "sk"

#   server_side_encryption {
#     enabled = false
#   }

#   point_in_time_recovery {
#     enabled = false
#   }

#   # GSI for queries by brain type
#   global_secondary_index {
#     name            = "brain-type-index"
#     hash_key        = "brain_type"
#     range_key       = "version"
#     projection_type = "ALL"
#   }

#   # GSI for queries by creator
#   global_secondary_index {
#     name            = "creator-index"
#     hash_key        = "creator_id"
#     range_key       = "created_at"
#     projection_type = "ALL"
#   }

#   attribute {
#     name = "pk"
#     type = "S"
#   }

#   attribute {
#     name = "sk"
#     type = "S"
#   }

#   attribute {
#     name = "brain_type"
#     type = "S"
#   }

#   attribute {
#     name = "version"
#     type = "S"
#   }

#   attribute {
#     name = "creator_id"
#     type = "S"
#   }

#   attribute {
#     name = "created_at"
#     type = "S"
#   }

#   tags = {
#     Name        = local.self_driving_car_name
#     Environment = var.environment_tag
#   }
# }

# resource "aws_dynamodb_table" "google_books_search" {
#   name         = "${local.google_books_search_name}-${var.environment_tag}"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "pk"

#   server_side_encryption {
#     enabled = false
#   }

#   point_in_time_recovery {
#     enabled = false
#   }

#   attribute {
#     name = "pk"
#     type = "S"
#   }

#   tags = {
#     Name        = local.google_books_search_name
#     Environment = var.environment_tag
#   }
# }

# resource "aws_dynamodb_table" "scrape_n_surf" {
#   name         = "${local.scrape_n_surf_name}-${var.environment_tag}"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "pk"

#   server_side_encryption {
#     enabled = false
#   }

#   point_in_time_recovery {
#     enabled = false
#   }

#   attribute {
#     name = "pk"
#     type = "S"
#   }

#   tags = {
#     Name        = local.scrape_n_surf_name
#     Environment = var.environment_tag
#   }
# }

# resource "aws_dynamodb_table" "dupe_gen" {
#   name         = "${local.dupe_gen_name}-${var.environment_tag}"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "pk"

#   server_side_encryption {
#     enabled = false
#   }

#   point_in_time_recovery {
#     enabled = false
#   }

#   attribute {
#     name = "pk"
#     type = "S"
#   }

#   tags = {
#     Name        = local.dupe_gen_name
#     Environment = var.environment_tag
#   }
# }

# resource "aws_dynamodb_table" "better_banking" {
#   name         = "${local.better_banking_name}-${var.environment_tag}"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "pk"

#   server_side_encryption {
#     enabled = false
#   }

#   point_in_time_recovery {
#     enabled = false
#   }

#   attribute {
#     name = "pk"
#     type = "S"
#   }

#   tags = {
#     Name        = local.better_banking_name
#     Environment = var.environment_tag
#   }
# }