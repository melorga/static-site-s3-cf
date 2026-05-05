# Static Site Infrastructure - S3 + CloudFront

[![AWS](https://img.shields.io/badge/AWS-S3%20%7C%20CloudFront%20%7C%20Route53-FF9900?style=for-the-badge&logo=amazon-aws)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/Terraform-Infrastructure-7B42BC?style=for-the-badge&logo=terraform)](https://terraform.io/)
[![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-CI%2FCD-2088FF?style=for-the-badge&logo=github-actions)](https://github.com/features/actions)

Production-ready static-website hosting on AWS S3 + CloudFront + Route53, packaged as a Terraform module. ACM, OAC, response-headers policy, and an opt-in access-logs bucket are wired in for you.

## Architecture

```
Route 53 (DNS, alias)  --->  CloudFront (OAC, cache + response headers)  --->  S3 (private, BucketOwnerEnforced)
                                                       |
                                                       v
                                              ACM cert (us-east-1)
```

## Features

- Private S3 origin with `BucketOwnerEnforced`, public-access-block, SSE-S3, optional versioning.
- CloudFront distribution with managed `CachingOptimized` and `CORS-S3Origin` policies; methods restricted to `GET/HEAD/OPTIONS`.
- `aws_cloudfront_response_headers_policy` providing HSTS (with `preload`), `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, and a baseline CSP of `default-src 'self'`.
- ACM certificate provisioned in `us-east-1` via a `aws.us_east_1` aliased provider (CloudFront requirement).
- Optional access-logs bucket (`enable_logging = true`) with the same hardening posture.
- IPv4 + IPv6 alias records on Route 53 when a custom domain is supplied.

## Requirements

- Terraform `>= 1.9, < 2.0`
- AWS provider `~> 6.0`
- AWS account with permissions to manage S3, CloudFront, ACM, and (optionally) Route53

## Quick start

```bash
git clone https://github.com/melorga/static-site-s3-cf.git
cd static-site-s3-cf/examples/basic

terraform init
terraform plan
terraform apply
```

`examples/basic/main.tf` declares both a default `aws` provider and a `aws.us_east_1` aliased provider, then passes the providers map into the module - copy that pattern into your own root module.

## Module usage

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

  site_name      = "my-marketing-site"
  environment    = "prod"
  custom_domain  = "www.example.com"
  hosted_zone_id = "Z123456ABCDEFG"
  enable_logging = true

  tags = {
    Project = "marketing"
    Owner   = "platform"
  }
}
```

## Inputs

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `site_name` | Name of the website/project; used for tags, OAC, response-headers policy | `string` | _required_ |
| `environment` | Environment tag (`prod`, `stage`, `dev`, ...) | `string` | `"prod"` |
| `bucket_name` | Override the generated S3 bucket name | `string` | `null` |
| `custom_domain` | Apex/sub domain to serve from (also requires `hosted_zone_id`) | `string` | `null` |
| `hosted_zone_id` | Route53 hosted zone ID for `custom_domain` | `string` | `null` |
| `subject_alternative_names` | Additional SANs for the ACM cert | `list(string)` | `[]` |
| `index_document` | S3 index document | `string` | `"index.html"` |
| `error_document` | S3 error document | `string` | `"error.html"` |
| `enable_versioning` | Enable S3 versioning on the website bucket | `bool` | `true` |
| `enable_logging` | Provision a logs bucket and enable S3 server access logging | `bool` | `false` |
| `price_class` | CloudFront price class | `string` | `"PriceClass_100"` |
| `viewer_protocol_policy` | CloudFront viewer protocol policy | `string` | `"redirect-to-https"` |
| `custom_error_responses` | List of CloudFront custom error responses | `list(object)` | 404 -> `/error.html` |
| `geo_restriction_type` | `none`, `whitelist`, or `blacklist` | `string` | `"none"` |
| `geo_restriction_locations` | Country codes for geo restriction | `list(string)` | `[]` |
| `tags` | Additional tags merged into every resource | `map(string)` | `{}` |

## Outputs

`bucket_name`, `bucket_domain_name`, `bucket_regional_domain_name`, `cloudfront_distribution_id`, `cloudfront_domain_name`, `cloudfront_hosted_zone_id`, `certificate_arn`, `website_url`, `s3_website_endpoint`.

## CI/CD

`.github/workflows/deploy.yml` covers fmt + validate, Trivy IaC scan, plan on PRs, and apply + S3 sync + CloudFront invalidation on `main`. Authentication is via OIDC - set the `AWS_OIDC_ROLE_ARN` repo secret to the IAM role you trust to GitHub Actions.

## Performance

Lighthouse runs on every deployment via `treosh/lighthouse-ci-action`. Reports are uploaded as workflow artifacts - check the latest run for current scores instead of relying on numbers in this README.

## Cost

Rough order of magnitude for a low-traffic marketing site (~100k page views / month):

- S3 storage + requests: a few cents
- CloudFront data transfer: low single-digit USD
- Route 53 hosted zone: ~$0.50
- ACM: free

Actual costs depend entirely on traffic; treat this as a sanity check, not a quote.

## Security model

- S3 bucket is private. CloudFront reads via OAC; the bucket policy allows only the `cloudfront.amazonaws.com` service principal scoped to the distribution ARN.
- All four `aws_s3_bucket_public_access_block` flags are `true` on both the website and (when enabled) logs buckets.
- `BucketOwnerEnforced` ownership controls disable ACLs entirely.
- HTTPS is enforced via `viewer_protocol_policy = "redirect-to-https"` and TLS 1.2_2021 minimum when a custom domain is in use.
- HSTS / X-Frame-Options / nosniff / Referrer-Policy / CSP are added by the response-headers policy.

## License

MIT - see [LICENSE](LICENSE).
