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
  default     = "1.31"
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
# Karpenter Variables (Performance & Scaling)
###############################################################





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
# ECR Variables
###############################################################

variable "repositories" {
  type    = list(string)
  default = ["lionpay-auth", "lionpay-wallet"]
}

