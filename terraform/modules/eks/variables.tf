variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "cluster_endpoint_public_access" {
  description = "Whether the cluster endpoint is publicly accessible"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

###############################################################
# System Managed Node Group Variables
###############################################################

variable "system_node_instance_types" {
  description = "Instance types for system node group"
  type        = list(string)
  default     = ["t4g.medium"]
}

variable "system_node_min_size" {
  description = "Minimum size of system node group"
  type        = number
  default     = 2
}

variable "system_node_max_size" {
  description = "Maximum size of system node group"
  type        = number
  default     = 4
}

variable "system_node_desired_size" {
  description = "Desired size of system node group"
  type        = number
  default     = 2
}

###############################################################
# Karpenter NodePool Variables
###############################################################

variable "node_pool_cpu_limit" {
  description = "CPU limit for each Karpenter node pool"
  type        = number
  default     = 1000
}

variable "ephemeral_storage_size" {
  description = "Size of ephemeral storage for Karpenter nodes"
  type        = string
  default     = "80Gi"
}

variable "ephemeral_storage_iops" {
  description = "IOPS for ephemeral storage"
  type        = number
  default     = 3000
}

variable "ephemeral_storage_throughput" {
  description = "Throughput for ephemeral storage (MB/s)"
  type        = number
  default     = 125
}

variable "t4g_instance_sizes" {
  description = "Allowed t4g instance CPU counts"
  type        = list(string)
  default     = ["2", "4", "8"]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
