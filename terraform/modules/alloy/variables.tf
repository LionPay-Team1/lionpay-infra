variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "grafana_cloud_metrics_username" {
  type      = string
  sensitive = true
}

variable "grafana_cloud_metrics_password" {
  type      = string
  sensitive = true
}

variable "grafana_cloud_logs_username" {
  type      = string
  sensitive = true
}

variable "grafana_cloud_logs_password" {
  type      = string
  sensitive = true
}

variable "grafana_cloud_traces_username" {
  type      = string
  sensitive = true
}

variable "grafana_cloud_traces_password" {
  type      = string
  sensitive = true
}

variable "grafana_cloud_metrics_url" {
  type = string
}

variable "grafana_cloud_logs_url" {
  type = string
}

variable "grafana_cloud_traces_url" {
  type = string
}
