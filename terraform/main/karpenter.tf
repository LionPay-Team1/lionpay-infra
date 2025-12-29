###############################################################
# Karpenter EC2NodeClass and NodePools
# Applied after EKS Blueprints Addons install Karpenter CRDs
###############################################################

# Seoul Cluster - EC2NodeClass
resource "kubectl_manifest" "ec2nodeclass_seoul" {
  provider = kubectl.seoul

  yaml_body = templatefile("${path.module}/../modules/eks/config/ec2nodeclass-t4g.yaml", {
    instance_profile_name = module.eks_seoul.karpenter_instance_profile_name
    cluster_name          = module.eks_seoul.cluster_name
    environment           = var.env
  })

  depends_on = [module.eks_blueprints_addons_seoul]
}

resource "kubectl_manifest" "nodepool_spot_seoul" {
  provider = kubectl.seoul

  yaml_body = templatefile("${path.module}/../modules/eks/config/nodepool-t4g-spot.yaml", {
    node_pool_cpu_limit = var.node_pool_cpu_limit
  })

  depends_on = [kubectl_manifest.ec2nodeclass_seoul]
}

resource "kubectl_manifest" "nodepool_ondemand_seoul" {
  provider = kubectl.seoul

  yaml_body = templatefile("${path.module}/../modules/eks/config/nodepool-t4g-ondemand.yaml", {
    node_pool_cpu_limit = var.node_pool_cpu_limit
  })

  depends_on = [kubectl_manifest.ec2nodeclass_seoul]
}

###############################################################
# Tokyo Cluster - Karpenter Configuration
###############################################################

resource "kubectl_manifest" "ec2nodeclass_tokyo" {
  provider = kubectl.tokyo

  yaml_body = templatefile("${path.module}/../modules/eks/config/ec2nodeclass-t4g.yaml", {
    instance_profile_name = module.eks_tokyo.karpenter_instance_profile_name
    cluster_name          = module.eks_tokyo.cluster_name
    environment           = var.env
  })

  depends_on = [module.eks_blueprints_addons_tokyo]
}

resource "kubectl_manifest" "nodepool_spot_tokyo" {
  provider = kubectl.tokyo

  yaml_body = templatefile("${path.module}/../modules/eks/config/nodepool-t4g-spot.yaml", {
    node_pool_cpu_limit = var.node_pool_cpu_limit
  })

  depends_on = [kubectl_manifest.ec2nodeclass_tokyo]
}

resource "kubectl_manifest" "nodepool_ondemand_tokyo" {
  provider = kubectl.tokyo

  yaml_body = templatefile("${path.module}/../modules/eks/config/nodepool-t4g-ondemand.yaml", {
    node_pool_cpu_limit = var.node_pool_cpu_limit
  })

  depends_on = [kubectl_manifest.ec2nodeclass_tokyo]
}
