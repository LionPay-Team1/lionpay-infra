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

variable "dynamodb_hash_key" {
  type = string
}

variable "dynamodb_range_key" {
  type    = string
  default = null
}

###############################################################
# S3 Variables
###############################################################

variable "s3_bucket_name" {
  type = string
}

###############################################################
# Grafana Cloud Variables
###############################################################


variable "grafana_cloud_metrics_username" {
  type      = string
  sensitive = true
}

variable "grafana_cloud_metrics_password" {
  type      = string
  sensitive = true
}

variable "grafana_cloud_logs_username" {
  type      = string
  sensitive = true
}

variable "grafana_cloud_logs_password" {
  type      = string
  sensitive = true
}

variable "grafana_cloud_traces_username" {
  type      = string
  sensitive = true
}

variable "grafana_cloud_traces_password" {
  type      = string
  sensitive = true
}

variable "grafana_cloud_metrics_url" {
  type = string
}

variable "grafana_cloud_logs_url" {
  type = string
}

variable "grafana_cloud_traces_url" {
  type = string
}

variable "fleetmanagement_url" {
  type = string
}

variable "fleetmanagement_username" {
  type      = string
  sensitive = true
}

variable "fleetmanagement_password" {
  type      = string
  sensitive = true
}
