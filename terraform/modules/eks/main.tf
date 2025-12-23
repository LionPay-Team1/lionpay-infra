locals {
  coredns_tolerations = var.enable_karpenter ? [
    {
      key    = "karpenter.sh/controller"
      value  = "true"
      effect = "NoSchedule"
    }
  ] : []

  managed_node_group_labels = var.enable_karpenter ? {
    "karpenter.sh/controller" = "true"
  } : {}

  managed_node_group_taints = var.enable_karpenter ? {
    karpenter = {
      key    = "karpenter.sh/controller"
      value  = "true"
      effect = "NO_SCHEDULE"
    }
  } : {}
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  enable_cluster_creator_admin_permissions = true
  endpoint_public_access                   = var.cluster_endpoint_public_access

  addons = {
    coredns = length(local.coredns_tolerations) > 0 ? {
      configuration_values = jsonencode({
        tolerations = local.coredns_tolerations
      })
    } : {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  enable_irsa = true

  eks_managed_node_groups = {
    karpenter = {
      ami_type       = var.karpenter_controller_ami_type
      instance_types = var.karpenter_controller_instance_types
      capacity_type  = var.karpenter_controller_capacity_type

      min_size     = var.karpenter_controller_min_size
      max_size     = var.karpenter_controller_max_size
      desired_size = var.karpenter_controller_desired_size

      labels = local.managed_node_group_labels
      taints = local.managed_node_group_taints
    }
  }

  node_security_group_tags = merge(var.tags, {
    "karpenter.sh/discovery" = var.karpenter_discovery_tag
  })

  tags = var.tags
}
