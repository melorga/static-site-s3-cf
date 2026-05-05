terraform {
  # TODO: replace placeholders with your real backend configuration before running CI.
  backend "s3" {
    bucket  = "REPLACE-ME-tfstate-bucket" # TODO: replace
    key     = "static-site-s3-cf/examples/basic/terraform.tfstate"
    region  = "us-east-1" # TODO: replace
    encrypt = true
    # dynamodb_table = "REPLACE-ME-tf-locks" # TODO: replace if you use DynamoDB locking
  }
}

provider "aws" {
  region = var.aws_region
}

# CloudFront ACM certificates must live in us-east-1 regardless of the caller region.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "static_site" {
  source = "../../modules/s3-cloudfront"

  providers = {
    aws            = aws
    aws.us_east_1  = aws.us_east_1
  }

  site_name   = var.site_name
  environment = var.environment

  # Optional: Custom domain configuration
  # custom_domain  = var.custom_domain
  # hosted_zone_id = var.hosted_zone_id

  price_class            = var.price_class
  viewer_protocol_policy = "redirect-to-https"

  enable_logging = var.enable_logging

  custom_error_responses = [
    {
      error_code         = 404
      response_code      = 404
      response_page_path = "/error.html"
    },
    {
      error_code         = 403
      response_code      = 404
      response_page_path = "/error.html"
    }
  ]

  tags = {
    Project     = var.site_name
    Environment = var.environment
    Owner       = "DevOps Team"
  }
}

# Upload sample files to S3
resource "aws_s3_object" "index" {
  bucket       = module.static_site.bucket_name
  key          = "index.html"
  source       = "website/index.html"
  content_type = "text/html"
  etag         = filemd5("website/index.html")
}

resource "aws_s3_object" "error" {
  bucket       = module.static_site.bucket_name
  key          = "error.html"
  source       = "website/error.html"
  content_type = "text/html"
  etag         = filemd5("website/error.html")
}

resource "aws_s3_object" "css" {
  bucket       = module.static_site.bucket_name
  key          = "styles.css"
  source       = "website/styles.css"
  content_type = "text/css"
  etag         = filemd5("website/styles.css")
}
