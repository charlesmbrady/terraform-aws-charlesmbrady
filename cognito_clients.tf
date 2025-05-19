locals {
  allowed_oauth_flows = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = ["email", "openid", "profile", "aws.cognito.signin.user.admin"]
  supported_identity_providers = ["COGNITO"]
}

resource "aws_cognito_user_pool_client" "mockdat" {
  name                                 = "mockdat"
  user_pool_id                         = aws_cognito_user_pool.charlesmbrady.id
  allowed_oauth_flows                  = local.allowed_oauth_flows
  allowed_oauth_flows_user_pool_client = local.allowed_oauth_flows_user_pool_client
  allowed_oauth_scopes                 = local.allowed_oauth_scopes
  callback_urls                        = var.cognito_client_mockdat_callback_urls
  default_redirect_uri                 = var.cognito_client_mockdat_default_redirect_uri
  logout_urls                          = var.cognito_client_mockdat_logout_urls
  supported_identity_providers         = local.supported_identity_providers
}

resource "aws_cognito_user_pool_client" "looper" {
  name                                 = "looper"
  user_pool_id                         = aws_cognito_user_pool.charlesmbrady.id
  allowed_oauth_flows                  = local.allowed_oauth_flows
  allowed_oauth_flows_user_pool_client = local.allowed_oauth_flows_user_pool_client
  allowed_oauth_scopes                 = local.allowed_oauth_scopes
  callback_urls                        = var.cognito_client_looper_callback_urls
  default_redirect_uri                 = var.cognito_client_looper_default_redirect_uri
  logout_urls                          = var.cognito_client_looper_logout_urls
  supported_identity_providers         = local.supported_identity_providers
}

resource "aws_cognito_user_pool_client" "cv_writer" {
  name                                 = "cv-writer"
  user_pool_id                         = aws_cognito_user_pool.charlesmbrady.id
  allowed_oauth_flows                  = local.allowed_oauth_flows
  allowed_oauth_flows_user_pool_client = local.allowed_oauth_flows_user_pool_client
  allowed_oauth_scopes                 = local.allowed_oauth_scopes
  callback_urls                        = var.cognito_client_cv_writer_callback_urls
  default_redirect_uri                 = var.cognito_client_cv_writer_default_redirect_uri
  logout_urls                          = var.cognito_client_cv_writer_logout_urls
  supported_identity_providers         = local.supported_identity_providers
}

# self-driving car
resource "aws_cognito_user_pool_client" "self_driving_car" {
  name                                 = "self-driving-car"
  user_pool_id                         = aws_cognito_user_pool.charlesmbrady.id
  allowed_oauth_flows                  = local.allowed_oauth_flows
  allowed_oauth_flows_user_pool_client = local.allowed_oauth_flows_user_pool_client
  allowed_oauth_scopes                 = local.allowed_oauth_scopes
  callback_urls                        = var.cognito_client_self_driving_car_callback_urls
  default_redirect_uri                 = var.cognito_client_self_driving_car_default_redirect_uri
  logout_urls                          = var.cognito_client_self_driving_car_logout_urls
  supported_identity_providers         = local.supported_identity_providers
}