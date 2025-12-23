variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "cluster_endpoint_public_access" {
  type    = bool
  default = true
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "enable_karpenter" {
  type    = bool
  default = true
}

variable "karpenter_discovery_tag" {
  type = string
}

variable "karpenter_controller_ami_type" {
  type    = string
  default = "BOTTLEROCKET_ARM_64"
}

variable "karpenter_controller_instance_types" {
  type    = list(string)
  default = ["t4g.medium"]
}

variable "karpenter_controller_capacity_type" {
  type    = string
  default = "ON_DEMAND"
}

variable "karpenter_controller_min_size" {
  type    = number
  default = 1
}

variable "karpenter_controller_max_size" {
  type    = number
  default = 3
}

variable "karpenter_controller_desired_size" {
  type    = number
  default = 1
}

variable "tags" {
  type    = map(string)
  default = {}
}
