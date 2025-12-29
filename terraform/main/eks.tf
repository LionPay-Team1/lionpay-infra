###############################################################
# EKS Clusters - Seoul (Hub) & Tokyo (Spoke)
###############################################################

# Seoul Cluster - ArgoCD Hub & Service
module "eks_seoul" {
  source = "../modules/eks"
  providers = {
    aws     = aws
    kubectl = kubectl.seoul
  }

  cluster_name    = local.seoul_cluster_name
  cluster_version = var.kubernetes_version
  vpc_id          = module.vpc_seoul.vpc_id
  subnet_ids      = module.vpc_seoul.private_subnets
  environment     = var.env

  node_pool_cpu_limit = var.node_pool_cpu_limit

  tags = local.tags
}

# Tokyo Cluster - Service Spoke
module "eks_tokyo" {
  source = "../modules/eks"
  providers = {
    aws     = aws.tokyo
    kubectl = kubectl.tokyo
  }

  cluster_name    = local.tokyo_cluster_name
  cluster_version = var.kubernetes_version
  vpc_id          = module.vpc_tokyo.vpc_id
  subnet_ids      = module.vpc_tokyo.private_subnets
  environment     = var.env

  node_pool_cpu_limit = var.node_pool_cpu_limit

  tags = local.tags
}

###############################################################
# IAM Role for ArgoCD Capability
###############################################################

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "argocd_capability" {
  name = "${local.name_prefix}-argocd-capability"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "capabilities.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "argocd_capability_secrets" {
  role       = aws_iam_role.argocd_capability.name
  policy_arn = "arn:aws:iam::aws:policy/AWSSecretsManagerClientReadOnlyAccess"
}

# Required policies for ArgoCD capability
resource "aws_iam_role_policy" "argocd_capability" {
  name = "${local.name_prefix}-argocd-capability-policy"
  role = aws_iam_role.argocd_capability.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sso:DescribeInstance",
          "sso:CreateApplication",
          "sso:DeleteApplication",
          "sso:PutApplicationGrant",
          "sso:PutApplicationAuthenticationMethod",
          "sso:PutApplicationAccessScope",
          "sso:ListApplicationAccessScopes",
          "sso:GetApplicationGrant"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sso-oauth:CreateTokenWithIAM"
        ]
        Resource = "*"
      }
    ]
  })
}

###############################################################
# EKS Capability - ArgoCD (Seoul Hub only)
###############################################################

resource "aws_eks_capability" "argocd_seoul" {
  cluster_name              = module.eks_seoul.cluster_name
  capability_name           = "argocd"
  type                      = "ARGOCD"
  role_arn                  = aws_iam_role.argocd_capability.arn
  delete_propagation_policy = "RETAIN"

  configuration {
    argo_cd {
      namespace = "argocd"
      rbac_role_mapping {
        identity {
          type = "SSO_GROUP"
          id   = var.argocd_admin_group_id
        }
        role = "ADMIN"
      }
      aws_idc {
        idc_instance_arn = var.idc_instance_arn
        idc_region       = coalesce(var.idc_region, var.region_seoul)
      }
    }
  }

  tags = local.tags

  depends_on = [module.eks_seoul, module.eks_blueprints_addons_seoul]
}

###############################################################
# EKS Blueprints Addons - Seoul (Hub)
###############################################################

module "eks_blueprints_addons_seoul" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.23"
  providers = {
    aws        = aws
    helm       = helm.seoul
    kubernetes = kubernetes.seoul
  }

  cluster_name      = module.eks_seoul.cluster_name
  cluster_endpoint  = module.eks_seoul.cluster_endpoint
  cluster_version   = module.eks_seoul.cluster_version
  oidc_provider_arn = module.eks_seoul.oidc_provider_arn

  enable_metrics_server = true

  # Note: EKS Addons (vpc-cni, coredns, kube-proxy) are managed by EKS module

  # Karpenter configuration
  enable_karpenter = true
  karpenter = {
    chart_version = "1.1.1"
  }
  karpenter_node = {
    iam_role_use_name_prefix = false
  }

  tags = local.tags
}

###############################################################
# EKS Blueprints Addons - Tokyo (Spoke)
###############################################################

module "eks_blueprints_addons_tokyo" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.23"
  providers = {
    aws        = aws.tokyo
    helm       = helm.tokyo
    kubernetes = kubernetes.tokyo
  }

  cluster_name      = module.eks_tokyo.cluster_name
  cluster_endpoint  = module.eks_tokyo.cluster_endpoint
  cluster_version   = module.eks_tokyo.cluster_version
  oidc_provider_arn = module.eks_tokyo.oidc_provider_arn

  enable_metrics_server = true

  # Note: EKS Addons (vpc-cni, coredns, kube-proxy) are managed by EKS module

  # Karpenter configuration
  enable_karpenter = true
  karpenter = {
    chart_version = "1.1.1"
  }
  karpenter_node = {
    iam_role_use_name_prefix = false
  }

  tags = local.tags
}
