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

variable "tags" {
  type    = map(string)
  default = {}
}

variable "kubernetes_version" {
  type    = string
  default = "1.34"
}

# VPC dependency outputs
variable "seoul_vpc_id" {
  type = string
}

variable "seoul_private_subnets" {
  type = list(string)
}

variable "tokyo_vpc_id" {
  type = string
}

variable "tokyo_private_subnets" {
  type = list(string)
}

# ArgoCD
variable "idc_instance_arn" {
  type = string
}

variable "idc_region" {
  type    = string
  default = null
}

variable "argocd_admin_group_id" {
  type = string
}

# Karpenter
variable "node_pool_cpu_limit" {
  type    = number
  default = 1000
}
