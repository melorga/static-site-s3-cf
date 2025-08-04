output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.website.id
}

output "bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.website.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.website.bucket_regional_domain_name
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "Hosted zone ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.hosted_zone_id
}

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = local.domain_name != null ? aws_acm_certificate.website[0].arn : null
}

output "website_url" {
  description = "URL of the website"
  value       = local.domain_name != null ? "https://${local.domain_name}" : "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "s3_website_endpoint" {
  description = "S3 website endpoint"
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}
