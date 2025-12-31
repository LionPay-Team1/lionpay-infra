resource "kubernetes_secret" "grafana_cloud_auth_seoul" {
  provider = kubernetes.seoul

  metadata {
    name      = "grafana-cloud-auth"
    namespace = "monitoring"
  }

  data = {
    metrics_username = var.metrics_username
    metrics_password = var.metrics_password
    logs_username    = var.logs_username
    logs_password    = var.logs_password
    traces_username  = var.traces_username
    traces_password  = var.traces_password
  }

  type = "Opaque"
}

resource "kubernetes_secret" "grafana_cloud_auth_tokyo" {
  provider = kubernetes.tokyo

  metadata {
    name      = "grafana-cloud-auth"
    namespace = "monitoring"
  }

  data = {
    metrics_username = var.metrics_username
    metrics_password = var.metrics_password
    logs_username    = var.logs_username
    logs_password    = var.logs_password
    traces_username  = var.traces_username
    traces_password  = var.traces_password
  }

  type = "Opaque"
}
