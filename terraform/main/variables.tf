variable "project_name" {
  type = string
}

variable "env" {
  type = string
}

variable "region_seoul" {
  type    = string
  default = "ap-northeast-2"
}

variable "region_tokyo" {
  type    = string
  default = "ap-northeast-1"
}

variable "dsql_witness_region" {
  description = "Region for the DSQL witness"
  type        = string
  default     = "ap-northeast-3"
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

variable "seoul_cluster_name" {
  description = "Optional custom name for Seoul EKS cluster"
  type        = string
  default     = null
}

variable "tokyo_cluster_name" {
  description = "Optional custom name for Tokyo EKS cluster"
  type        = string
  default     = null
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

variable "seoul_enable_nat_gateway" {
  type    = bool
  default = true
}

variable "seoul_single_nat_gateway" {
  type    = bool
  default = true
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

variable "tokyo_enable_nat_gateway" {
  type    = bool
  default = true
}

variable "tokyo_single_nat_gateway" {
  type    = bool
  default = true
}

###############################################################
# Karpenter Variables
###############################################################

variable "node_pool_cpu_limit" {
  description = "CPU limit for Karpenter node pools"
  type        = number
  default     = 1000
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

variable "dynamodb_hash_key_type" {
  type    = string
  default = "S"
}

variable "dynamodb_range_key" {
  type    = string
  default = null
}

variable "dynamodb_range_key_type" {
  type    = string
  default = "S"
}

variable "dynamodb_billing_mode" {
  type    = string
  default = "PAY_PER_REQUEST"
}

variable "dynamodb_point_in_time_recovery" {
  type    = bool
  default = false
}

variable "dynamodb_deletion_protection" {
  type    = bool
  default = false
}

###############################################################
# S3 Variables
###############################################################

variable "s3_bucket_name" {
  type = string
}

variable "s3_versioning_enabled" {
  type    = bool
  default = true
}

variable "s3_sse_algorithm" {
  type    = string
  default = "AES256"
}
