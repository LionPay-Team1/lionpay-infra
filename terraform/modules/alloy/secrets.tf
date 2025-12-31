resource "kubernetes_secret_v1" "grafana_cloud_auth" {
  metadata {
    name      = "grafana-cloud-auth"
    namespace = kubernetes_namespace_v1.alloy.metadata[0].name
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
