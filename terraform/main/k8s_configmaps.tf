###############################################################
# Global Kubernetes ConfigMaps
###############################################################

# Seoul Cluster (Hub)
resource "kubernetes_config_map_v1" "global_config_seoul" {
  provider = kubernetes.seoul

  metadata {
    name      = "global-config"
    namespace = "default"
  }

  data = {
    "AWS_REGION" = "ap-northeast-2"
  }

  depends_on = [module.eks_seoul]
}

# Tokyo Cluster (Spoke)
resource "kubernetes_config_map_v1" "global_config_tokyo" {
  provider = kubernetes.tokyo

  metadata {
    name      = "global-config"
    namespace = "default"
  }

  data = {
    "AWS_REGION" = "ap-northeast-1"
  }

  depends_on = [module.eks_tokyo]
}
