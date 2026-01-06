###############################################################
# Global Kubernetes Namespaces
###############################################################

resource "kubernetes_namespace_v1" "lionpay_seoul" {
  provider = kubernetes.seoul
  metadata {
    name = local.app_namespace
  }
}

resource "kubernetes_namespace_v1" "lionpay_tokyo" {
  provider = kubernetes.tokyo
  metadata {
    name = local.app_namespace
  }
}
