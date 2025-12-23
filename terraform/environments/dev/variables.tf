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
  default = "1.30"
}

variable "admin_seoul_cluster_name" {
  type    = string
  default = null
}

variable "service_seoul_cluster_name" {
  type    = string
  default = null
}

variable "service_tokyo_cluster_name" {
  type    = string
  default = null
}

variable "admin_seoul_vpc_cidr" {
  type = string
}

variable "admin_seoul_azs" {
  type = list(string)
}

variable "admin_seoul_private_subnet_cidrs" {
  type = list(string)
}

variable "admin_seoul_public_subnet_cidrs" {
  type = list(string)
}

variable "admin_seoul_enable_nat_gateway" {
  type    = bool
  default = true
}

variable "admin_seoul_single_nat_gateway" {
  type    = bool
  default = true
}

variable "service_seoul_vpc_cidr" {
  type = string
}

variable "service_seoul_azs" {
  type = list(string)
}

variable "service_seoul_private_subnet_cidrs" {
  type = list(string)
}

variable "service_seoul_public_subnet_cidrs" {
  type = list(string)
}

variable "service_seoul_enable_nat_gateway" {
  type    = bool
  default = true
}

variable "service_seoul_single_nat_gateway" {
  type    = bool
  default = true
}

variable "service_tokyo_vpc_cidr" {
  type = string
}

variable "service_tokyo_azs" {
  type = list(string)
}

variable "service_tokyo_private_subnet_cidrs" {
  type = list(string)
}

variable "service_tokyo_public_subnet_cidrs" {
  type = list(string)
}

variable "service_tokyo_enable_nat_gateway" {
  type    = bool
  default = true
}

variable "service_tokyo_single_nat_gateway" {
  type    = bool
  default = true
}

variable "admin_enable_karpenter" {
  type    = bool
  default = true
}

variable "service_seoul_enable_karpenter" {
  type    = bool
  default = true
}

variable "service_tokyo_enable_karpenter" {
  type    = bool
  default = true
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

variable "karpenter_node_class_name" {
  type    = string
  default = "default"
}

variable "karpenter_node_pool_name" {
  type    = string
  default = "default"
}

variable "karpenter_ami_alias" {
  type    = string
  default = "bottlerocket@latest"
}

variable "karpenter_instance_categories" {
  type    = list(string)
  default = ["c", "m", "r"]
}

variable "karpenter_instance_cpus" {
  type    = list(string)
  default = ["4", "8", "16", "32"]
}

variable "karpenter_instance_generations" {
  type    = list(string)
  default = ["2"]
}

variable "karpenter_capacity_types" {
  type    = list(string)
  default = ["spot"]
}

variable "karpenter_architectures" {
  type    = list(string)
  default = ["arm64"]
}

variable "karpenter_node_pool_cpu_limit" {
  type    = number
  default = 1000
}

variable "karpenter_consolidation_policy" {
  type    = string
  default = "WhenEmpty"
}

variable "karpenter_consolidate_after" {
  type    = string
  default = "30s"
}

variable "karpenter_chart_version" {
  type    = string
  default = "1.0.2"
}

variable "karpenter_apply_k8s_resources" {
  type    = bool
  default = false
}

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

variable "dsql_deletion_protection_enabled" {
  type    = bool
  default = false
}

variable "dsql_force_destroy" {
  type    = bool
  default = false
}

variable "dsql_kms_encryption_key" {
  type    = string
  default = null
}

variable "dsql_witness_region" {
  type = string
}

variable "dsql_region" {
  type    = string
  default = null
}

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
