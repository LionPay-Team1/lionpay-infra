###############################################################
# EKS Clusters - Seoul (Hub) & Tokyo (Spoke)
###############################################################

# Seoul Cluster - ArgoCD Hub & Service
module "eks_seoul" {
  source = "../modules/eks"
  providers = {
    aws  = aws.seoul
    helm = helm.seoul
  }

  cluster_name    = local.seoul_cluster_name
  cluster_version = var.kubernetes_version
  vpc_id          = module.vpc_seoul.vpc_id
  private_subnets = module.vpc_seoul.private_subnets
  environment     = var.env

  # Managed Node Group settings
  mng_instance_types = var.mng_instance_types
  mng_min_size       = var.mng_min_size
  mng_max_size       = var.mng_max_size
  mng_desired_size   = var.mng_desired_size

  # Karpenter Helm chart credentials


  tags = local.tags
}

# Tokyo Cluster - Service Spoke
module "eks_tokyo" {
  source = "../modules/eks"
  providers = {
    aws  = aws.tokyo
    helm = helm.tokyo
  }

  cluster_name    = local.tokyo_cluster_name
  cluster_version = var.kubernetes_version
  vpc_id          = module.vpc_tokyo.vpc_id
  private_subnets = module.vpc_tokyo.private_subnets
  environment     = var.env

  # Managed Node Group settings
  mng_instance_types = var.mng_instance_types
  mng_min_size       = var.mng_min_size
  mng_max_size       = var.mng_max_size
  mng_desired_size   = var.mng_desired_size

  # Karpenter Helm chart credentials


  tags = local.tags
}

###############################################################
# IAM Role for ArgoCD Capability
###############################################################

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
        idc_region       = var.idc_region
      }
    }
  }

  tags = local.tags

  depends_on = [module.eks_seoul]
}
