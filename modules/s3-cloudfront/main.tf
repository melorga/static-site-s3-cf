terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Generate a random suffix for bucket name uniqueness
resource "random_string" "bucket_suffix" {
  count   = var.bucket_name == null ? 1 : 0
  length  = 8
  special = false
  upper   = false
}

locals {
  bucket_name = var.bucket_name != null ? var.bucket_name : "${var.site_name}-${random_string.bucket_suffix[0].result}"
  domain_name = var.custom_domain != null ? var.custom_domain : null
  
  # Common tags
  common_tags = merge(var.tags, {
    Project     = var.site_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

# S3 bucket for static website hosting
resource "aws_s3_bucket" "website" {
  bucket = local.bucket_name
  tags   = local.common_tags
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public read policy
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website.arn
          }
        }
      }
    ]
  })
}

# S3 bucket website configuration
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}

# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${var.site_name}-oac"
  description                       = "OAC for ${var.site_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ACM Certificate (if custom domain is provided)
resource "aws_acm_certificate" "website" {
  count           = local.domain_name != null ? 1 : 0
  domain_name     = local.domain_name
  validation_method = "DNS"

  subject_alternative_names = var.subject_alternative_names

  lifecycle {
    create_before_destroy = true
  }

  tags = local.common_tags
}

# Route53 record for certificate validation
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in flatten([
      local.domain_name != null ? aws_acm_certificate.website[0].domain_validation_options : []
    ]) : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.hosted_zone_id
}

# ACM certificate validation
resource "aws_acm_certificate_validation" "website" {
  count                   = local.domain_name != null ? 1 : 0
  certificate_arn         = aws_acm_certificate.website[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "website" {
  aliases = local.domain_name != null ? [local.domain_name] : []

  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.website.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${var.site_name}"
  default_root_object = var.index_document
  price_class         = var.price_class

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.website.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = var.viewer_protocol_policy
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl

    compress = true
  }

  # Custom error responses
  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    content {
      error_code         = custom_error_response.value.error_code
      response_code      = custom_error_response.value.response_code
      response_page_path = custom_error_response.value.response_page_path
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = local.domain_name == null
    acm_certificate_arn            = local.domain_name != null ? aws_acm_certificate_validation.website[0].certificate_arn : null
    ssl_support_method             = local.domain_name != null ? "sni-only" : null
    minimum_protocol_version       = local.domain_name != null ? "TLSv1.2_2021" : null
  }

  tags = local.common_tags
}

# Route53 record for the website (if custom domain is provided)
resource "aws_route53_record" "website" {
  count   = local.domain_name != null ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = local.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

# Route53 AAAA record for IPv6 (if custom domain is provided)
resource "aws_route53_record" "website_ipv6" {
  count   = local.domain_name != null ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = local.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}
