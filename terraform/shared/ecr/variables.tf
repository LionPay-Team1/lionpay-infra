variable "repositories" {
  type    = list(string)
  default = ["lionpay-auth", "lionpay-wallet"]
}

variable "image_tag_mutability" {
  type    = string
  default = "IMMUTABLE"
}

variable "scan_on_push" {
  type    = bool
  default = true
}

variable "force_delete" {
  type    = bool
  default = false
}

variable "encryption_type" {
  type    = string
  default = "AES256"
}

variable "kms_key_arn" {
  type    = string
  default = null
}

variable "lifecycle_policy" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
