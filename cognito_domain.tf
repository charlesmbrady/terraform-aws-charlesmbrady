
resource "aws_route53_record" "sso_a" {
  name = aws_cognito_user_pool_domain.charlesmbrady.domain
  type = "A"
  zone_id = var.hosted_zone_id

  alias {
    evaluate_target_health = false
    name = aws_cognito_user_pool_domain.charlesmbrady.cloudfront_distribution_arn
    zone_id =  "Z2FDTNDATAQYW2" # Cognito zone id
  }
}

# aws cognito user pool domain resource
resource "aws_cognito_user_pool_domain" "charlesmbrady" {
  domain = var.sso_domain_name
  user_pool_id = aws_cognito_user_pool.charlesmbrady.id
    certificate_arn = var.certificate_arn
}