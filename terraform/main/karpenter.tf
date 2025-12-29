###############################################################
# Karpenter - Seoul (Hub) & Tokyo (Spoke)
###############################################################

module "karpenter_seoul" {
  source = "../modules/karpenter"
  providers = {
    aws  = aws.seoul
    helm = helm.seoul
  }

  cluster_name              = module.eks_seoul.cluster_name
  cluster_endpoint          = module.eks_seoul.cluster_endpoint
  cluster_oidc_provider_arn = module.eks_seoul.oidc_provider_arn
  node_iam_role_name        = module.eks_seoul.karpenter_node_iam_role_name



  tags = local.tags
}

module "karpenter_tokyo" {
  source = "../modules/karpenter"
  providers = {
    aws  = aws.tokyo
    helm = helm.tokyo
  }

  cluster_name              = module.eks_tokyo.cluster_name
  cluster_endpoint          = module.eks_tokyo.cluster_endpoint
  cluster_oidc_provider_arn = module.eks_tokyo.oidc_provider_arn
  node_iam_role_name        = module.eks_tokyo.karpenter_node_iam_role_name



  tags = local.tags
}
