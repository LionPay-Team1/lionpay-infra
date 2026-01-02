resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "alloy" {
  name             = "grafana-k8s-monitoring"
  chart            = "k8s-monitoring"
  repository       = "https://grafana.github.io/helm-charts"
  namespace        = kubernetes_namespace_v1.monitoring.metadata[0].name
  create_namespace = false

  set_sensitive {
    name  = "cluster.name"
    value = var.cluster_name
  }

  values = [
    templatefile("${path.module}/values-k8s-monitoring.tfpl", {
      cluster_name                   = var.cluster_name
      grafana_cloud_metrics_username = var.grafana_cloud_metrics_username
      grafana_cloud_metrics_password = var.grafana_cloud_metrics_password
      grafana_cloud_logs_username    = var.grafana_cloud_logs_username
      grafana_cloud_logs_password    = var.grafana_cloud_logs_password
      grafana_cloud_traces_username  = var.grafana_cloud_traces_username
      grafana_cloud_traces_password  = var.grafana_cloud_traces_password
      grafana_cloud_metrics_url      = var.grafana_cloud_metrics_url
      grafana_cloud_logs_url         = var.grafana_cloud_logs_url
      grafana_cloud_traces_url       = var.grafana_cloud_traces_url
    })
  ]
}


