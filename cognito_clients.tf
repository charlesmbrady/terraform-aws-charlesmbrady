# resource "aws_cognito_user_pool_client" "mockdat" {
#   name                                 = "mockdat"
#   user_pool_id                         = aws_cognito_user_pool.charlesmbrady.id
#   allowed_oauth_flows                  = ["code"]
#   allowed_oauth_flows_user_pool_client = true
#   allowed_oauth_scopes                 = ["email", "openid", "profile"]
#   callback_urls                        = ["http://localhost:3000"]
#   default_redirect_uri                 = "http://localhost:3000"
#   logout_urls                          = ["http://localhost:3000"]
#   supported_identity_providers         = ["COGNITO"]
# }