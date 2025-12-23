variable "cluster_identifier" {
  type = string
}

variable "engine" {
  type    = string
  default = "aurora-postgresql"
}

variable "engine_version" {
  type    = string
  default = null
}

variable "database_name" {
  type    = string
  default = null
}

variable "master_username" {
  type = string
}

variable "master_password" {
  type      = string
  sensitive = true
}

variable "port" {
  type    = number
  default = 5432
}

variable "subnet_group_name" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "allowed_cidr_blocks" {
  type = list(string)
}

variable "instance_class" {
  type    = string
  default = "db.r6g.large"
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "publicly_accessible" {
  type    = bool
  default = false
}

variable "backup_retention_period" {
  type    = number
  default = 1
}

variable "apply_immediately" {
  type    = bool
  default = true
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
