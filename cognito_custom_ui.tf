resource "aws_cognito_user_pool_ui_customization" "example" {
  css        = file("${path.module}/cognito_custom_ui.css")
  image_file = filebase64("${path.module}/charles_portrait.png")

  # Refer to the aws_cognito_user_pool_domain resource's
  # user_pool_id attribute to ensure it is in an 'Active' state
  user_pool_id = aws_cognito_user_pool_domain.charlesmbrady.user_pool_id
}