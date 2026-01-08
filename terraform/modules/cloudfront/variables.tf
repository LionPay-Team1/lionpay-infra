variable "s3_bucket_name" {
  type        = string
  description = "S3 bucket name for frontend assets."
}

variable "app_domain_name" {
  type        = string
  description = "Custom domain for lionpay.shop distribution."
}

variable "admin_domain_name" {
  type        = string
  description = "Custom domain for admin.lionpay.shop distribution."
}

variable "api_domain_name" {
  type        = string
  description = "Custom domain for api.lionpay.shop distribution."
}

variable "app_backend_origin_domain_name" {
  type        = string
  description = "Origin DNS name for the app /v1/* backend (ALB DNS)."
}

variable "api_origin_domain_name" {
  type        = string
  description = "Origin DNS name for the API distribution (ALB DNS)."
}

variable "app_acm_arn" {
  type        = string
  description = "ACM certificate ARN for lionpay.shop (us-east-1)."
}

variable "admin_acm_arn" {
  type        = string
  description = "ACM certificate ARN for admin.lionpay.shop (us-east-1)."
}

variable "api_acm_arn" {
  type        = string
  description = "ACM certificate ARN for api.lionpay.shop (us-east-1)."
}

variable "oac_name" {
  type        = string
  description = "Name for the shared Origin Access Control."
}

variable "oac_description" {
  type        = string
  description = "Description for the shared Origin Access Control."
}

variable "price_class" {
  type        = string
  description = "CloudFront price class."
  default     = "PriceClass_All"
}

variable "app_tags" {
  type        = map(string)
  description = "Tags to apply to the app distribution."
  default     = {}
}

variable "admin_tags" {
  type        = map(string)
  description = "Tags to apply to the admin distribution."
  default     = {}
}

variable "api_tags" {
  type        = map(string)
  description = "Tags to apply to the api distribution."
  default     = {}
}

variable "app_web_acl_id" {
  type        = string
  description = "Optional WAF Web ACL ARN for lionpay.shop."
  default     = null
}

variable "admin_web_acl_id" {
  type        = string
  description = "Optional WAF Web ACL ARN for admin.lionpay.shop."
  default     = null
}

variable "api_web_acl_id" {
  type        = string
  description = "Optional WAF Web ACL ARN for api.lionpay.shop."
  default     = null
}

variable "app_s3_origin_id_override" {
  type        = string
  description = "Optional override for app S3 origin_id to match existing console values."
  default     = null
}

variable "admin_s3_origin_id_override" {
  type        = string
  description = "Optional override for admin S3 origin_id to match existing console values."
  default     = null
}

variable "app_backend_origin_id_override" {
  type        = string
  description = "Optional override for app /v1/* origin_id to match existing console values."
  default     = null
}

variable "api_default_origin_id_override" {
  type        = string
  description = "Optional override for api default origin_id to match existing console values."
  default     = null
}

variable "api_ordered_origin_id_override" {
  type        = string
  description = "Optional override for api /v1/* origin_id to match existing console values."
  default     = null
}

variable "api_default_root_object" {
  type        = string
  description = "Optional default root object for the API distribution."
  default     = null
}
