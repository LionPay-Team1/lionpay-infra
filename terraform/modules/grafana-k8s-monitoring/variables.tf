variable "namespace" {
  type    = string
  default = "monitoring"
}

variable "cluster_name" {
  type = string
}

variable "destinations_prometheus_url" {
  type = string
}

variable "destinations_prometheus_username" {
  type = string
}

variable "destinations_prometheus_password" {
  type = string
}

variable "destinations_loki_url" {
  type = string
}

variable "destinations_loki_username" {
  type = string
}

variable "destinations_loki_password" {
  type = string
}

variable "destinations_otlp_url" {
  type = string
}

variable "destinations_otlp_username" {
  type = string
}

variable "destinations_otlp_password" {
  type = string
}

variable "fleetmanagement_url" {
  type = string
}

variable "fleetmanagement_username" {
  type = string
}

variable "fleetmanagement_password" {
  type = string
}
