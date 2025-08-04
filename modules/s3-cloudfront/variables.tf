variable "site_name" {
  description = "Name of the website/project"
  type        = string
}

variable "environment" {
  description = "Environment (prod, stage, dev)"
  type        = string
  default     = "prod"
}

variable "bucket_name" {
  description = "S3 bucket name (optional, will generate if not provided)"
  type        = string
  default     = null
}

variable "custom_domain" {
  description = "Custom domain name for the website"
  type        = string
  default     = null
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID (required if using custom domain)"
  type        = string
  default     = null
}

variable "subject_alternative_names" {
  description = "Subject alternative names for the SSL certificate"
  type        = list(string)
  default     = []
}

variable "index_document" {
  description = "Index document for the website"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Error document for the website"
  type        = string
  default     = "error.html"
}

variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "price_class" {
  description = "CloudFront distribution price class"
  type        = string
  default     = "PriceClass_100"
  
  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "Price class must be PriceClass_All, PriceClass_200, or PriceClass_100."
  }
}

variable "viewer_protocol_policy" {
  description = "Viewer protocol policy"
  type        = string
  default     = "redirect-to-https"
  
  validation {
    condition     = contains(["allow-all", "https-only", "redirect-to-https"], var.viewer_protocol_policy)
    error_message = "Viewer protocol policy must be allow-all, https-only, or redirect-to-https."
  }
}

variable "min_ttl" {
  description = "Minimum TTL for CloudFront caching"
  type        = number
  default     = 0
}

variable "default_ttl" {
  description = "Default TTL for CloudFront caching"
  type        = number
  default     = 3600
}

variable "max_ttl" {
  description = "Maximum TTL for CloudFront caching"
  type        = number
  default     = 86400
}

variable "custom_error_responses" {
  description = "Custom error responses for CloudFront"
  type = list(object({
    error_code         = number
    response_code      = number
    response_page_path = string
  }))
  default = [
    {
      error_code         = 404
      response_code      = 404
      response_page_path = "/error.html"
    }
  ]
}

variable "geo_restriction_type" {
  description = "Geographic restriction type"
  type        = string
  default     = "none"
  
  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction_type)
    error_message = "Geo restriction type must be none, whitelist, or blacklist."
  }
}

variable "geo_restriction_locations" {
  description = "Geographic restriction locations (country codes)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
