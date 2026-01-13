###############################################################
# Global Kubernetes Secrets (JWT, etc.)
###############################################################

# Seoul Cluster (Hub) - App Secrets
resource "kubernetes_secret_v1" "app_secrets_seoul" {
  provider = kubernetes.seoul

  metadata {
    name      = "app-secrets"
    namespace = local.app_namespace
  }

  data = {
    "JWT_SECRET" = var.jwt_secret
  }

  type = "Opaque"

  depends_on = [
    module.eks_seoul,
    kubernetes_namespace_v1.lionpay_seoul
  ]
}

# Tokyo Cluster (Spoke) - App Secrets
resource "kubernetes_secret_v1" "app_secrets_tokyo" {
  provider = kubernetes.tokyo

  metadata {
    name      = "app-secrets"
    namespace = local.app_namespace
  }

  data = {
    "JWT_SECRET" = var.jwt_secret
  }

  type = "Opaque"

  depends_on = [
    module.eks_tokyo,
    kubernetes_namespace_v1.lionpay_tokyo
  ]
}
