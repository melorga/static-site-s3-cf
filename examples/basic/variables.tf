variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "site_name" {
  description = "Name of the website"
  type        = string
  default     = "my-static-site"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "demo"
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

# Uncomment these if you want to use a custom domain
# variable "custom_domain" {
#   description = "Custom domain name"
#   type        = string
#   default     = null
# }

# variable "hosted_zone_id" {
#   description = "Route53 hosted zone ID"
#   type        = string
#   default     = null
# }
