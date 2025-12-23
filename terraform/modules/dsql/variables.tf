variable "deletion_protection_enabled" {
  type    = bool
  default = false
}

variable "force_destroy" {
  type    = bool
  default = false
}

variable "kms_encryption_key" {
  type    = string
  default = null
}

variable "witness_region" {
  type    = string
  default = null
}

variable "region" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
