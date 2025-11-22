locals {
  name_env_prefix = "${lower(var.root_project_name_prefix)}-${lower(var.environment)}"
}

resource "aws_route53_record" "alias" {
  zone_id = var.hosted_zone_id
  name    = var.alias_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cf.domain_name
    zone_id                = aws_cloudfront_distribution.cf.hosted_zone_id
    evaluate_target_health = false
  }
}


#############################
## S3 Bucket for the Environment
#############################

resource "aws_s3_bucket" "website_bucket" {
  bucket = "${local.name_env_prefix}-website-content"

  website {
    index_document = "index.html"
    error_document = "index.html" # SPA fallback
  }
}

#############################
## CloudFront Origin Access Identity & S3 Policy
#############################

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${local.name_env_prefix} distribution"
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

#############################
## CloudFront Distribution
#############################

resource "aws_cloudfront_distribution" "cf" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = var.domain_aliases

  origin {
    domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id   = "${local.name_env_prefix}--s3-origin"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    target_origin_id       = "${local.name_env_prefix}--s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
    compress    = true
  }



  # Custom error responses for SPA deep linking
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "AU", "NZ", "IE"]
    }
  }

  tags = {
    Environment  = var.environment
    Root_Project = var.root_project_name_prefix
  }
}
