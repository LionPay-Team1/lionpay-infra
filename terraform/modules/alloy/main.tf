resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "alloy" {
  name             = "grafana-cloud"
  chart            = "grafana-cloud-onboarding"
  repository       = "https://grafana.github.io/helm-charts"
  namespace        = kubernetes_namespace_v1.monitoring.metadata[0].name
  create_namespace = false

  set_sensitive {
    name  = "cluster.name"
    value = var.cluster_name
  }

  set_sensitive {
    name  = "grafanaCloud.fleetManagement.url"
    value = var.fleet_url
  }

  set_sensitive {
    name  = "grafanaCloud.fleetManagement.auth.username"
    value = var.fleet_username
  }

  set_sensitive {
    name  = "grafanaCloud.fleetManagement.auth.password"
    value = var.fleet_password
  }
}
