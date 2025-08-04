terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "static_site" {
  source = "../../modules/s3-cloudfront"

  site_name   = var.site_name
  environment = var.environment

  # Optional: Custom domain configuration
  # custom_domain   = var.custom_domain
  # hosted_zone_id  = var.hosted_zone_id

  # CloudFront configuration
  price_class               = var.price_class
  viewer_protocol_policy   = "redirect-to-https"
  
  # Caching configuration
  default_ttl = 3600
  max_ttl     = 86400

  # Custom error responses
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
