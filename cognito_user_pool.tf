# // Cognito user pool configuration
# resource "aws_cognito_user_pool" "charlesmbrady" {
#   name                     = var.cognito_user_pool_name
#   username_attributes      = ["email"]
#   auto_verified_attributes = ["email"]
#   schema {
#     name                = "email"
#     attribute_data_type = "String"
#     mutable             = true
#     required            = true
#   }
  
#   password_policy {
#     minimum_length    = 8
#     require_lowercase = true
#     require_numbers   = true
#     require_symbols   = true
#     require_uppercase = true
#   }
# }