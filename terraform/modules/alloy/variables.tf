variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "metrics_username" {
  type      = string
  sensitive = true
}

variable "metrics_password" {
  type      = string
  sensitive = true
}

variable "logs_username" {
  type      = string
  sensitive = true
}

variable "logs_password" {
  type      = string
  sensitive = true
}

variable "traces_username" {
  type      = string
  sensitive = true
}

variable "traces_password" {
  type      = string
  sensitive = true
}
