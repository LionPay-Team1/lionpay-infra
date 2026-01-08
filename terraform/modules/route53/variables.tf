variable "zone_name" {
  description = "Route53 hosted zone name."
  type        = string
}

# CloudFront distribution domain names
variable "app_cloudfront_domain_name" {
  description = "CloudFront domain name for lionpay.shop (e.g., d1offmun0zt2o7.cloudfront.net)."
  type        = string
}

variable "admin_cloudfront_domain_name" {
  description = "CloudFront domain name for admin.lionpay.shop (e.g., d16srywbso6fsa.cloudfront.net)."
  type        = string
}

variable "api_cloudfront_domain_name" {
  description = "CloudFront domain name for api.lionpay.shop (e.g., d20x9f76m12qrg.cloudfront.net)."
  type        = string
}


