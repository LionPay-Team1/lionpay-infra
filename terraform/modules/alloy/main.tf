resource "kubernetes_namespace_v1" "alloy" {
  metadata {
    name = "alloy"
  }
}

resource "helm_release" "alloy" {
  name             = "alloy"
  chart            = "alloy"
  repository       = "https://grafana.github.io/helm-charts"
  namespace        = kubernetes_namespace_v1.alloy.metadata[0].name
  create_namespace = false
  values           = [templatefile("${path.module}/values-alloy.tftpl", { cluster_name = var.cluster_name })]

  depends_on = [
    kubernetes_secret_v1.grafana_cloud_auth
  ]

  ### metrics
  set_sensitive {
    name  = "destinations[0].auth.username"
    value = var.metrics_username
  }
  set_sensitive {
    name  = "destinations[0].auth.password"
    value = var.metrics_password
  }

  ### logs
  set_sensitive {
    name  = "destinations[1].auth.username"
    value = var.logs_username
  }
  set_sensitive {
    name  = "destinations[1].auth.password"
    value = var.logs_password
  }

  ### traces
  set_sensitive {
    name  = "destinations[2].auth.username"
    value = var.traces_username
  }
  set_sensitive {
    name  = "destinations[2].auth.password"
    value = var.traces_password
  }
}
