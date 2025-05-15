resource "aws_cognito_user_pool_client" "mockdat" {
  name                                 = "mockdat"
  user_pool_id                         = aws_cognito_user_pool.charlesmbrady.id
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  callback_urls                        = ["http://localhost:3000"]
  default_redirect_uri                 = "http://localhost:3000"
  logout_urls                          = ["http://localhost:3000"]
  supported_identity_providers         = ["COGNITO"]
}

resource "aws_cognito_user_pool_client" "looper" {
  name                                 = "looper"
  user_pool_id                         = aws_cognito_user_pool.charlesmbrady.id
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  callback_urls                        = ["http://localhost:3000"]
  default_redirect_uri                 = "http://localhost:3000"
  logout_urls                          = ["http://localhost:3000"]
  supported_identity_providers         = ["COGNITO"]
}

resource "aws_cognito_user_pool_client" "cv_writer" {
  name                                 = "cv-writer"
  user_pool_id                         = aws_cognito_user_pool.charlesmbrady.id
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  callback_urls                        = ["http://localhost:3000"]
  default_redirect_uri                 = "http://localhost:3000"
  logout_urls                          = ["http://localhost:3000"]
  supported_identity_providers         = ["COGNITO"]
}

# self-driving car
resource "aws_cognito_user_pool_client" "self_driving_car" {
  name                                 = "self-driving-car"
  user_pool_id                         = aws_cognito_user_pool.charlesmbrady.id
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  callback_urls                        = ["http://localhost:3000"]
  default_redirect_uri                 = "http://localhost:3000"
  logout_urls                          = ["http://localhost:3000"]
  supported_identity_providers         = ["COGNITO"]
}