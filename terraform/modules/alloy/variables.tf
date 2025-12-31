variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "fleet_url" {
  type = string
}

variable "fleet_username" {
  type = string
}

variable "fleet_password" {
  type      = string
  sensitive = true
}
