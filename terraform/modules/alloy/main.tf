resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "alloy" {
  name             = "grafana-k8s-monitoring"
  chart            = "k8s-monitoring"
  repository       = "https://grafana.github.io/helm-charts"
  namespace        = kubernetes_namespace_v1.monitoring.metadata[0].name
  create_namespace = false
  atomic           = true
  timeout          = 300

  set {
    name  = "cluster.name"
    value = var.cluster_name
  }

  values = [
    templatefile("${path.module}/values-k8s-monitoring.tfpl", {
      cluster_name = var.cluster_name
    })
  ]

  set {
    name  = "destinations[0].url"
    value = var.grafana_cloud_metrics_url
  }

  set_sensitive {
    name  = "destinations[0].auth.username"
    value = var.grafana_cloud_metrics_username
  }

  set_sensitive {
    name  = "destinations[0].auth.password"
    value = var.grafana_cloud_metrics_password
  }

  set {
    name  = "destinations[1].url"
    value = var.grafana_cloud_logs_url
  }

  set_sensitive {
    name  = "destinations[1].auth.username"
    value = var.grafana_cloud_logs_username
  }

  set_sensitive {
    name  = "destinations[1].auth.password"
    value = var.grafana_cloud_logs_password
  }

  set {
    name  = "destinations[2].url"
    value = var.grafana_cloud_traces_url
  }

  set_sensitive {
    name  = "destinations[2].auth.username"
    value = var.grafana_cloud_traces_username
  }

  set_sensitive {
    name  = "destinations[2].auth.password"
    value = var.grafana_cloud_traces_password
  }

  set {
    name  = "clusterMetrics.opencost.opencost.exporter.defaultClusterId"
    value = var.cluster_name
  }

  set {
    name  = "clusterMetrics.opencost.opencost.prometheus.external.url"
    value = trimsuffix(var.grafana_cloud_metrics_url, "/push")
  }

  set {
    name  = "alloy-metrics.remoteConfig.url"
    value = var.fleetmanagement_url
  }

  set_sensitive {
    name  = "alloy-metrics.remoteConfig.auth.username"
    value = var.fleetmanagement_username
  }

  set_sensitive {
    name  = "alloy-metrics.remoteConfig.auth.password"
    value = var.fleetmanagement_password
  }

  set {
    name  = "alloy-singleton.remoteConfig.url"
    value = var.fleetmanagement_url
  }

  set_sensitive {
    name  = "alloy-singleton.remoteConfig.auth.username"
    value = var.fleetmanagement_username
  }

  set_sensitive {
    name  = "alloy-singleton.remoteConfig.auth.password"
    value = var.fleetmanagement_password
  }

  set {
    name  = "alloy-logs.remoteConfig.url"
    value = var.fleetmanagement_url
  }

  set_sensitive {
    name  = "alloy-logs.remoteConfig.auth.username"
    value = var.fleetmanagement_username
  }

  set_sensitive {
    name  = "alloy-logs.remoteConfig.auth.password"
    value = var.fleetmanagement_password
  }

  set {
    name  = "alloy-receiver.remoteConfig.url"
    value = var.fleetmanagement_url
  }

  set_sensitive {
    name  = "alloy-receiver.remoteConfig.auth.username"
    value = var.fleetmanagement_username
  }

  set_sensitive {
    name  = "alloy-receiver.remoteConfig.auth.password"
    value = var.fleetmanagement_password
  }
}


