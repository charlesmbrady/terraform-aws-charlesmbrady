/* ----------------------------------- API ---------------------------------- */
resource "aws_api_gateway_domain_name" "api_domain_name" {
  certificate_arn = aws_acm_certificate_validation.apigateway_certificate.certificate_arn
  domain_name     = "api.${var.services_api_domain_name}"
  security_policy = "TLS_1_2"
}

resource "aws_acm_certificate" "apigateway_certificate" {
  domain_name       = "api.${var.services_api_domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "apigateway_certificate" {
  certificate_arn         = aws_acm_certificate.apigateway_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.apigateway_certificate_validation : record.fqdn]
}

resource "aws_route53_record" "apigateway_certificate_validation" {
  for_each = {
    for dvo in aws_acm_certificate.apigateway_certificate.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = data.aws_route53_zone.charlesmbrady_services.zone_id
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}

# An AWS Alias A record to the api gateway
resource "aws_route53_record" "api" {
  name    = aws_api_gateway_domain_name.api_domain_name.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.charlesmbrady_services.zone_id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.api_domain_name.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.api_domain_name.cloudfront_zone_id
  }

  # No tags
}


# An AWS Alias AAAA record to the api gateway
resource "aws_route53_record" "api_aaaa" {
  name    = aws_api_gateway_domain_name.api_domain_name.domain_name
  type    = "AAAA"
  zone_id = data.aws_route53_zone.charlesmbrady_services.zone_id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.api_domain_name.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.api_domain_name.cloudfront_zone_id
  }

  # No tags
}


resource "aws_api_gateway_base_path_mapping" "services_api_domain_name_mapping" {
  api_id      = module.services_api.rest_api_id
  stage_name  = module.services_api.api_stage
  domain_name = aws_api_gateway_domain_name.api_domain_name.domain_name
}