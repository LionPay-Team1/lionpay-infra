###############################################################
# EKS Cluster Auth Data Sources
###############################################################

# EKS Cluster Auth for Seoul (Hub)
data "aws_eks_cluster_auth" "seoul" {
  name       = module.eks_seoul.cluster_name
  depends_on = [module.eks_seoul]
}

# EKS Cluster Auth for Tokyo (Spoke)
data "aws_eks_cluster_auth" "tokyo" {
  provider   = aws.tokyo
  name       = module.eks_tokyo.cluster_name
  depends_on = [module.eks_tokyo]
}

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

  cluster_name         = local.seoul_cluster_name
  cluster_version      = var.kubernetes_version
  vpc_id               = module.vpc_seoul.vpc_id
  private_subnets      = module.vpc_seoul.private_subnets
  environment          = var.env
  admin_principal_arns = var.admin_principal_arns

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

  cluster_name         = local.tokyo_cluster_name
  cluster_version      = var.kubernetes_version
  vpc_id               = module.vpc_tokyo.vpc_id
  private_subnets      = module.vpc_tokyo.private_subnets
  environment          = var.env
  admin_principal_arns = var.admin_principal_arns

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
  node_iam_role_arn         = module.eks_seoul.karpenter_node_iam_role_arn

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
  node_iam_role_arn         = module.eks_tokyo.karpenter_node_iam_role_arn

  tags = local.tags
}

###############################################################
# Karpenter Config Automation
###############################################################

resource "local_file" "karpenter_seoul_manifest" {
  content = templatefile("${path.module}/config/${var.env}-karpenter.yaml", {
    cluster_name          = module.eks_seoul.cluster_name
    environment           = var.env
    instance_profile_name = module.eks_seoul.karpenter_instance_profile_name
  })
  filename = "${path.module}/.terraform/karpenter_seoul.yaml"
}

resource "null_resource" "karpenter_seoul_apply" {
  triggers = {
    manifest_sha1 = sha1(local_file.karpenter_seoul_manifest.content)
  }

  # 1. Update Kubeconfig
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks_seoul.cluster_name} --region ap-northeast-2"
    environment = {
      KUBECONFIG = "${path.module}/.terraform/kubeconfig_seoul"
    }
  }

  # 2. Apply Manifest
  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.karpenter_seoul_manifest.filename}"
    environment = {
      KUBECONFIG = "${path.module}/.terraform/kubeconfig_seoul"
    }
  }

  depends_on = [module.karpenter_seoul]
}

resource "local_file" "karpenter_tokyo_manifest" {
  content = templatefile("${path.module}/config/${var.env}-karpenter.yaml", {
    cluster_name          = module.eks_tokyo.cluster_name
    environment           = var.env
    instance_profile_name = module.eks_tokyo.karpenter_instance_profile_name
  })
  filename = "${path.module}/.terraform/karpenter_tokyo.yaml"
}

resource "null_resource" "karpenter_tokyo_apply" {
  triggers = {
    manifest_sha1 = sha1(local_file.karpenter_tokyo_manifest.content)
  }

  # 1. Update Kubeconfig
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks_tokyo.cluster_name} --region ap-northeast-1"
    environment = {
      KUBECONFIG = "${path.module}/.terraform/kubeconfig_tokyo"
    }
  }

  # 2. Apply Manifest
  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.karpenter_tokyo_manifest.filename}"
    environment = {
      KUBECONFIG = "${path.module}/.terraform/kubeconfig_tokyo"
    }
  }

  depends_on = [module.karpenter_tokyo]
}

###############################################################
# Alloy (Grafana Cloud Monitoring) - Seoul & Tokyo
###############################################################

module "monitoring_seoul" {
  source = "../modules/grafana-k8s-monitoring"

  providers = {
    helm       = helm.seoul
    kubernetes = kubernetes.seoul
  }

  cluster_name = local.seoul_cluster_name

  destinations_prometheus_url      = var.destinations_prometheus_url
  destinations_prometheus_username = var.destinations_prometheus_username
  destinations_prometheus_password = var.destinations_prometheus_password

  destinations_loki_url      = var.destinations_loki_url
  destinations_loki_username = var.destinations_loki_username
  destinations_loki_password = var.destinations_loki_password

  destinations_otlp_url      = var.destinations_otlp_url
  destinations_otlp_username = var.destinations_otlp_username
  destinations_otlp_password = var.destinations_otlp_password

  fleetmanagement_url      = var.fleetmanagement_url
  fleetmanagement_username = var.fleetmanagement_username
  fleetmanagement_password = var.fleetmanagement_password
}

module "monitoring_tokyo" {
  source = "../modules/grafana-k8s-monitoring"

  providers = {
    helm       = helm.tokyo
    kubernetes = kubernetes.tokyo
  }

  cluster_name = local.tokyo_cluster_name

  destinations_prometheus_url      = var.destinations_prometheus_url
  destinations_prometheus_username = var.destinations_prometheus_username
  destinations_prometheus_password = var.destinations_prometheus_password

  destinations_loki_url      = var.destinations_loki_url
  destinations_loki_username = var.destinations_loki_username
  destinations_loki_password = var.destinations_loki_password

  destinations_otlp_url      = var.destinations_otlp_url
  destinations_otlp_username = var.destinations_otlp_username
  destinations_otlp_password = var.destinations_otlp_password

  fleetmanagement_url      = var.fleetmanagement_url
  fleetmanagement_username = var.fleetmanagement_username
  fleetmanagement_password = var.fleetmanagement_password
}
