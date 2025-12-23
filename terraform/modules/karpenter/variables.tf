variable "cluster_name" {
  type = string
}

variable "cluster_endpoint" {
  type = string
}

variable "namespace" {
  type    = string
  default = "karpenter"
}

variable "node_iam_role_name" {
  type = string
}

variable "node_class_name" {
  type    = string
  default = "default"
}

variable "node_pool_name" {
  type    = string
  default = "default"
}

variable "ami_alias" {
  type    = string
  default = "bottlerocket@latest"
}

variable "discovery_tag" {
  type = string
}

variable "instance_categories" {
  type    = list(string)
  default = ["c", "m", "r"]
}

variable "instance_cpus" {
  type    = list(string)
  default = ["4", "8", "16", "32"]
}

variable "instance_generations" {
  type    = list(string)
  default = ["2"]
}

variable "capacity_types" {
  type    = list(string)
  default = ["spot"]
}

variable "architectures" {
  type    = list(string)
  default = ["arm64"]
}

variable "node_pool_cpu_limit" {
  type    = number
  default = 1000
}

variable "consolidation_policy" {
  type    = string
  default = "WhenEmpty"
}

variable "consolidate_after" {
  type    = string
  default = "30s"
}

variable "chart_version" {
  type    = string
  default = "1.0.2"
}

variable "apply_kubernetes_resources" {
  type    = bool
  default = true
}

variable "repository_username" {
  type    = string
  default = null
}

variable "repository_password" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
