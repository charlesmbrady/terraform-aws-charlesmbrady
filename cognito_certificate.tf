resource "aws_acm_certificate" "sso" {
  domain_name       = aws_route53_zone.sso.name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "sso" {
  certificate_arn         = aws_acm_certificate.sso.arn
  validation_record_fqdns = [aws_route53_record.sso.fqdn]
}

resource "aws_route53_record" "sso" {
    zone_id = aws_route53_zone.sso.zone_id

    name    = aws_acm_certificate.sso.domain_validation_options.*.resource_record_name[0]
    type    = aws_acm_certificate.sso.domain_validation_options.*.resource_record_type[0]
    records = [aws_acm_certificate.sso.domain_validation_options.*.resource_record_value[0]]
    ttl     = 30
 
}
