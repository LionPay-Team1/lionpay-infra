###############################################################
# Karpenter EC2NodeClass and NodePools
# Applied after EKS Blueprints Addons install Karpenter CRDs
###############################################################

# Seoul Cluster - EC2NodeClass
resource "kubernetes_manifest" "ec2nodeclass_seoul" {
  provider = kubernetes.seoul

  manifest = yamldecode(templatefile("${path.module}/config/ec2nodeclass.yaml", {
    name                  = "default"
    instance_profile_name = module.eks_seoul.karpenter_instance_profile_name
    cluster_name          = module.eks_seoul.cluster_name
    environment           = var.env
  }))

  depends_on = [module.eks_blueprints_addons_seoul]
}

resource "kubernetes_manifest" "nodepool_seoul" {
  provider = kubernetes.seoul

  manifest = yamldecode(file("${path.module}/config/${var.env}/nodepool.yaml"))

  depends_on = [kubernetes_manifest.ec2nodeclass_seoul]
}

###############################################################
# Tokyo Cluster - Karpenter Configuration
###############################################################

resource "kubernetes_manifest" "ec2nodeclass_tokyo" {
  provider = kubernetes.tokyo

  manifest = yamldecode(templatefile("${path.module}/config/ec2nodeclass.yaml", {
    name                  = "default"
    instance_profile_name = module.eks_tokyo.karpenter_instance_profile_name
    cluster_name          = module.eks_tokyo.cluster_name
    environment           = var.env
  }))

  depends_on = [module.eks_blueprints_addons_tokyo]
}

resource "kubernetes_manifest" "nodepool_tokyo" {
  provider = kubernetes.tokyo

  manifest = yamldecode(file("${path.module}/config/${var.env}/nodepool.yaml"))

  depends_on = [kubernetes_manifest.ec2nodeclass_tokyo]
}
