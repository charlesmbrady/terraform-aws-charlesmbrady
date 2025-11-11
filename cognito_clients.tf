locals {
  allowed_oauth_flows = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = ["email", "openid", "profile", "aws.cognito.signin.user.admin"]
  supported_identity_providers = ["COGNITO"]
  access_token_validity = 1
  id_token_validity = 1
  refresh_token_validity = 30
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
  access_token_validity                = local.access_token_validity
  id_token_validity                    = local.id_token_validity
  refresh_token_validity               = local.refresh_token_validity
}

resource "aws_cognito_user_pool_client" "apps" {
  name                                 = "apps"
  user_pool_id                         = aws_cognito_user_pool.charlesmbrady.id
  allowed_oauth_flows                  = local.allowed_oauth_flows
  allowed_oauth_flows_user_pool_client = local.allowed_oauth_flows_user_pool_client
  allowed_oauth_scopes                 = local.allowed_oauth_scopes
  callback_urls                        = var.cognito_client_apps_callback_urls
  default_redirect_uri                 = var.cognito_client_apps_default_redirect_uri
  logout_urls                          = var.cognito_client_apps_logout_urls
  supported_identity_providers         = local.supported_identity_providers
  access_token_validity                = local.access_token_validity
  id_token_validity                    = local.id_token_validity
  refresh_token_validity               = local.refresh_token_validity
}
