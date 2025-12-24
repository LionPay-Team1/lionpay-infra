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

variable "deletion_protection_enabled" {
  type    = bool
  default = false
}

# VPC dependencies
variable "seoul_vpc_id" {
  type = string
}

variable "seoul_vpc_cidr_block" {
  type = string
}

variable "seoul_private_subnets" {
  type = list(string)
}

variable "tokyo_vpc_id" {
  type = string
}

variable "tokyo_vpc_cidr_block" {
  type = string
}

variable "tokyo_private_subnets" {
  type = list(string)
}

# EKS dependencies
variable "seoul_oidc_provider_arn" {
  type = string
}

variable "tokyo_oidc_provider_arn" {
  type = string
}
