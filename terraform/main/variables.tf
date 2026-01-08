variable "project_name" {
  type = string
}

variable "central_region" {
  description = "Central region for Hub cluster (ArgoCD), ECR, etc."
  type        = string
  default     = "ap-northeast-2"
}

variable "env" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS clusters"
  type        = string
  default     = "1.34"
}

variable "admin_principal_arns" {
  description = "List of IAM ARNs to grant EKS Cluster Admin permissions"
  type        = list(string)
  default     = []
}

###############################################################
# ArgoCD Capability Variables
###############################################################

variable "idc_instance_arn" {
  description = "AWS Identity Center instance ARN for ArgoCD capability"
  type        = string
}

variable "idc_region" {
  description = "AWS Identity Center region (optional, defaults to Seoul)"
  type        = string
  default     = null
}

variable "argocd_admin_group_id" {
  description = "IAM Identity Center Group ID for ArgoCD Admin access"
  type        = string
}

variable "git_repo_url" {
  description = "Git repository URL for ArgoCD applications"
  type        = string
  default     = "https://github.com/LionPay-Team1/lionpay-infra"
}

variable "git_repo_revision" {
  description = "Git repository revision (branch, tag, or commit) to use for ArgoCD applications"
  type        = string
  default     = "main"
}

###############################################################
# VPC Variables - Seoul (Hub)
###############################################################

variable "seoul_vpc_cidr" {
  type = string
}

variable "seoul_azs" {
  type = list(string)
}

variable "seoul_private_subnet_cidrs" {
  type = list(string)
}

variable "seoul_public_subnet_cidrs" {
  type = list(string)
}



###############################################################
# VPC Variables - Tokyo (Spoke)
###############################################################

variable "tokyo_vpc_cidr" {
  type = string
}

variable "tokyo_azs" {
  type = list(string)
}

variable "tokyo_private_subnet_cidrs" {
  type = list(string)
}

variable "tokyo_public_subnet_cidrs" {
  type = list(string)
}

###############################################################
# Managed Node Group Variables (Karpenter Controller & Addons)
###############################################################

variable "mng_instance_types" {
  description = "Instance types for managed node group"
  type        = list(string)
  default     = ["t4g.large"]
}

variable "mng_min_size" {
  description = "Minimum size of managed node group"
  type        = number
  default     = 1
}

variable "mng_max_size" {
  description = "Maximum size of managed node group"
  type        = number
  default     = 4
}

variable "mng_desired_size" {
  description = "Desired size of managed node group"
  type        = number
  default     = 2
}


###############################################################
# DynamoDB Variables
###############################################################

variable "dynamodb_table_name" {
  type = string
}


###############################################################
# S3 Variables
###############################################################


###############################################################
# Grafana Cloud Variables
###############################################################

variable "destinations_prometheus_url" {
  type = string
}

variable "destinations_prometheus_username" {
  type = string
}

variable "destinations_prometheus_password" {
  type = string
}

variable "destinations_loki_url" {
  type = string
}

variable "destinations_loki_username" {
  type = string
}

variable "destinations_loki_password" {
  type = string
}

variable "destinations_otlp_url" {
  type = string
}

variable "destinations_otlp_username" {
  type = string
}

variable "destinations_otlp_password" {
  type = string
}

variable "fleetmanagement_url" {
  type = string
}

variable "fleetmanagement_username" {
  type = string
}

variable "fleetmanagement_password" {
  type = string
}

variable "otel_exporter_otlp_endpoint" {
  type = string
}

###############################################################
# JWT Variables
###############################################################

variable "jwt_secret" {
  description = "Secret key for JWT signing"
  type        = string
  sensitive   = true
}

###############################################################
# Route53 Variables
###############################################################

variable "route53_zone_name" {
  description = "Route53 hosted zone name."
  type        = string
  default     = "lionpay.shop"
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for lionpay.shop."
  type        = string
}

###############################################################
# CloudFront Variables
###############################################################

variable "cloudfront_frontend_bucket_name" {
  description = "Frontend S3 bucket name."
  type        = string
  default     = "lionpay-dev-frontend"
}

variable "cloudfront_app_backend_origin_domain_name" {
  description = "Origin DNS name for lionpay.shop /api/* backend."
  type        = string
}

variable "cloudfront_api_origin_domain_name" {
  description = "Origin DNS name for api.lionpay.shop (ALB)."
  type        = string
}

variable "cloudfront_api_default_root_object" {
  description = "Optional default root object for api.lionpay.shop."
  type        = string
  default     = null
}

variable "cloudfront_app_s3_origin_id_override" {
  description = "Optional override for app S3 origin_id."
  type        = string
  default     = null
}

variable "cloudfront_admin_s3_origin_id_override" {
  description = "Optional override for admin S3 origin_id."
  type        = string
  default     = null
}

variable "cloudfront_app_backend_origin_id_override" {
  description = "Optional override for app /api/* origin_id."
  type        = string
  default     = null
}

variable "cloudfront_api_default_origin_id_override" {
  description = "Optional override for api default origin_id."
  type        = string
  default     = null
}

variable "cloudfront_api_ordered_origin_id_override" {
  description = "Optional override for api /api/* origin_id."
  type        = string
  default     = null
}

variable "cloudfront_oac_name" {
  description = "Origin Access Control name."
  type        = string
}

variable "cloudfront_oac_description" {
  description = "Origin Access Control description."
  type        = string
}

variable "cloudfront_price_class" {
  description = "CloudFront price class."
  type        = string
  default     = "PriceClass_All"
}

variable "cloudfront_app_tags" {
  description = "Tags to apply to lionpay.shop distribution."
  type        = map(string)
  default     = {}
}

variable "cloudfront_admin_tags" {
  description = "Tags to apply to admin.lionpay.shop distribution."
  type        = map(string)
  default     = {}
}

variable "cloudfront_api_tags" {
  description = "Tags to apply to api.lionpay.shop distribution."
  type        = map(string)
  default     = {}
}

variable "cloudfront_app_web_acl_id" {
  description = "Optional WAF Web ACL ARN for lionpay.shop."
  type        = string
  default     = null
}

variable "cloudfront_admin_web_acl_id" {
  description = "Optional WAF Web ACL ARN for admin.lionpay.shop."
  type        = string
  default     = null
}

variable "cloudfront_api_web_acl_id" {
  description = "Optional WAF Web ACL ARN for api.lionpay.shop."
  type        = string
  default     = null
}

variable "cloudfront_api_acm_arn" {
  description = "ACM certificate ARN for api.lionpay.shop (us-east-1)."
  type        = string
}

variable "cloudfront_app_acm_arn" {
  description = "ACM certificate ARN for lionpay.shop (us-east-1)."
  type        = string
}

variable "cloudfront_admin_acm_arn" {
  description = "ACM certificate ARN for admin.lionpay.shop (us-east-1)."
  type        = string
}
