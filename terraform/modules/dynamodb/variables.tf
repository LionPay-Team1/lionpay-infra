variable "table_name" {
  type = string
}

variable "billing_mode" {
  type    = string
  default = "PAY_PER_REQUEST"
}

variable "hash_key" {
  type = string
}

variable "hash_key_type" {
  type    = string
  default = "S"
}

variable "range_key" {
  type    = string
  default = null
}

variable "range_key_type" {
  type    = string
  default = "S"
}

variable "point_in_time_recovery" {
  type    = bool
  default = false
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "replica_regions" {
  description = "List of regions to create replicas in"
  type = list(object({
    region_name = string
    kms_key_arn = optional(string)
  }))
  default = []
}

variable "global_secondary_indexes" {
  description = "List of Global Secondary Indexes"
  type = list(object({
    name               = string
    hash_key           = string
    hash_key_type      = string
    range_key          = optional(string)
    range_key_type     = optional(string)
    projection_type    = optional(string, "ALL")
    non_key_attributes = optional(list(string))
  }))
  default = []
}

variable "server_side_encryption" {
  description = "Enable server-side encryption"
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
