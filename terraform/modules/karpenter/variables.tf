variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  type        = string
}

variable "cluster_oidc_provider_arn" {
  description = "The OIDC Provider ARN for the EKS cluster"
  type        = string
}

variable "node_iam_role_name" {
  description = "The name of the IAM role for Karpenter nodes"
  type        = string
}

variable "karpenter_version" {
  description = "Version of the Karpenter Helm chart"
  type        = string
  default     = "1.6.2" # Matches default in eks/variables.tf
}



variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "metrics_server_version" {
  description = "Version of the metrics-server Helm chart"
  type        = string
  default     = "3.12.2"
}
