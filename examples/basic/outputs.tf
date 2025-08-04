output "website_url" {
  description = "URL of the deployed website"
  value       = module.static_site.website_url
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.static_site.cloudfront_domain_name
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.static_site.bucket_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.static_site.cloudfront_distribution_id
}
