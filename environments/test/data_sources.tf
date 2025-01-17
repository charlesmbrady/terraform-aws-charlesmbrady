data "aws_route53_zone" "main_zone" {
  name         = "charlesmbrady.com."
  private_zone = false
}