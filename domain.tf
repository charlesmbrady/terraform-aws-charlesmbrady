# /* ----------------------------------- API ---------------------------------- */
resource "aws_api_gateway_domain_name" "api_domain_name" {
  certificate_arn = aws_acm_certificate_validation.apigateway_certificate.certificate_arn
  domain_name     = "api.${var.charlesmbrady_api_root_domain_name}"
  security_policy = "TLS_1_2"
}




# An AWS Alias A record to the api gateway
resource "aws_route53_record" "api" {
  name    = aws_api_gateway_domain_name.api_domain_name.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.charlesmbrady.zone_id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.api_domain_name.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.api_domain_name.cloudfront_zone_id
  }

}

resource "aws_api_gateway_base_path_mapping" "api_domain_name_mapping" {
  api_id      = module.charlesmbrady_api.rest_api_id
  stage_name  = module.charlesmbrady_api.api_stage
  domain_name = aws_api_gateway_domain_name.api_domain_name.domain_name
}