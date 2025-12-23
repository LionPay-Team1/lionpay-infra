variable "project_name" {
  type = string
}

variable "env" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "node_groups" {
  type = map(any)
}

variable "enable_karpenter" {
  type    = bool
  default = true
}

variable "argocd_capability_role_arn" {
  description = "IAM Role ARN for EKS ArgoCD capability"
  type        = string
}

variable "idc_instance_arn" {
  description = "IAM Identity Center instance ARN (arn:aws:sso:::instance/...)"
  type        = string
}

variable "argocd_namespace" {
  description = "Namespace to install ArgoCD into"
  type        = string
  default     = "argocd"
}
