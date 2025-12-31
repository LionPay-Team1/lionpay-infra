resource "helm_release" "grafana_k8s_monitoring_seoul" {
  provider          = helm.seoul
  name              = "grafana-k8s-monitoring"
  chart             = "k8s-monitoring"
  repository        = "https://grafana.github.io/helm-charts"
  namespace         = "monitoring"
  create_namespace  = true
  values            = [file("${path.module}/values-k8s-monitoring-seoul.yaml")]

  depends_on = [
    kubernetes_secret.grafana_cloud_auth_seoul
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

resource "helm_release" "grafana_k8s_monitoring_tokyo" {
  provider          = helm.tokyo
  name              = "grafana-k8s-monitoring"
  chart             = "k8s-monitoring"
  repository        = "https://grafana.github.io/helm-charts"
  namespace         = "monitoring"
  create_namespace  = true
  values            = [file("${path.module}/values-k8s-monitoring-tokyo.yaml")]

  depends_on = [
    kubernetes_secret.grafana_cloud_auth_tokyo
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
