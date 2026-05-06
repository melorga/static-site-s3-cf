# Static Site Module - S3 + CloudFront

Terraform module that provisions a private S3 bucket fronted by a CloudFront distribution, with optional Route53 + ACM for custom domains and an optional access-logs bucket.

## Features

- Private S3 origin with `BucketOwnerEnforced`, full public-access-block, SSE-S3.
- CloudFront distribution using AWS-managed `CachingOptimized` + `CORS-S3Origin` policies and a custom response-headers policy (HSTS + preload, `X-Frame-Options: DENY`, `nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, baseline CSP).
- ACM certificate provisioned via the required `aws.us_east_1` aliased provider so it lives in `us-east-1` regardless of the caller region.
- Opt-in access-logs bucket (`enable_logging = true`) with the same hardening posture.
- IPv4 + IPv6 Route53 alias records when a custom domain is supplied.

## Provider configuration

This module declares `configuration_aliases = [aws.us_east_1]`. The caller MUST pass both providers:

```hcl
provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "static_site" {
  source = "github.com/melorga/static-site-s3-cf//modules/s3-cloudfront"

  providers = {
    aws            = aws
    aws.us_east_1  = aws.us_east_1
  }

  site_name      = "my-site"
  environment    = "prod"
  custom_domain  = "www.example.com"
  hosted_zone_id = "Z123456ABCDEFG"
  enable_logging = true
}
```

A full working example (with `terraform init`/`apply` instructions) lives in [`examples/basic`](../../examples/basic).

## Requirements

- Terraform `>= 1.9, < 2.0`
- AWS provider `~> 6.0`

## Inputs / Outputs

See [`variables.tf`](./variables.tf) and [`outputs.tf`](./outputs.tf) - the root [README](../../README.md) documents each variable in a table.
