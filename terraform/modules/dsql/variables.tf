variable "deletion_protection_enabled" {
  description = "Whether deletion protection is enabled"
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "Whether to force destroy the cluster"
  type        = bool
  default     = false
}

variable "kms_encryption_key" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = null
}

variable "witness_region" {
  description = "Witness region for multi-region setup"
  type        = string
  default     = null
}

variable "linked_cluster_arns" {
  description = "Set of linked cluster ARNs for multi-region peering"
  type        = set(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
