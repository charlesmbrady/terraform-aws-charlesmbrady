# Adopt existing website settings after upgrading cloudfront-module to 3.0.0.
# These imports preserve the existing buckets and website behavior.

import {
  to = module.main.module.apps.aws_s3_bucket_website_configuration.website_bucket
  id = "apps-test-website-content"
}

import {
  to = module.main.module.charlesmbrady.aws_s3_bucket_website_configuration.website_bucket
  id = "charlesmbrady-test-website-content"
}

import {
  to = module.main.module.mockdat.aws_s3_bucket_website_configuration.website_bucket
  id = "mockdat-test-website-content"
}
