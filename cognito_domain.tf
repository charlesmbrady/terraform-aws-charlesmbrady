resource "aws_route53_delegation_set" "sso" {
}

resource "aws_route53_zone" "sso" {
  name = var.sso_domain_name
  delegation_set_id = aws_route53_delegation_set.sso.id
}

resource "aws_route53_record" "sso_a" {
  name = aws_cognito_user_pool_domain.charlesmbrady.domain
  type = "A"
  zone_id = aws_route53_zone.sso.zone_id

  alias {
    evaluate_target_health = false
    name = aws_cognito_user_pool_domain.charlesmbrady.cloudfront_distribution_arn
    zone_id =  "Z2FDTNDATAQYW2" # Cognito zone id
  }
}

resource "aws_route53_record" "sso_aaaa" {
  name = aws_cognito_user_pool_domain.charlesmbrady.domain
  type = "AAAA"
  zone_id = aws_route53_zone.sso.zone_id

  alias {
    evaluate_target_health = false
    name = aws_cognito_user_pool_domain.charlesmbrady.cloudfront_distribution_arn
    zone_id =  "Z2FDTNDATAQYW2" # Cognito zone id
  }

}

# aws cognito user pool domain resource
resource "aws_cognito_user_pool_domain" "charlesmbrady" {
  domain = aws_route53_zone.sso.name
  user_pool_id = aws_cognito_user_pool.charlesmbrady.id
    certificate_arn = aws_acm_certificate.sso.arn
}