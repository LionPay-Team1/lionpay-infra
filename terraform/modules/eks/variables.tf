variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.34"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be created"
  type        = string
}

variable "private_subnets" {
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
  default     = 1
}

###############################################################
# Karpenter NodePool Variables
###############################################################

variable "node_pool_cpu_limit" {
  description = "CPU limit for each Karpenter node pool"
  type        = number
  default     = 10
}

variable "ephemeral_storage_size" {
  description = "Size of ephemeral storage for Karpenter nodes"
  type        = string
  default     = "30Gi"
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






