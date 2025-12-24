###############################################################
# EKS Clusters - Seoul (Hub) & Tokyo (Spoke)
###############################################################

module "eks_seoul" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.36"

  cluster_name    = "${var.project_name}-${var.env}-seoul"
  cluster_version = var.kubernetes_version

  vpc_id     = var.seoul_vpc_id
  subnet_ids = var.seoul_private_subnets

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  tags = var.tags
}

module "eks_tokyo" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.36"
  providers = {
    aws = aws.tokyo
  }

  cluster_name    = "${var.project_name}-${var.env}-tokyo"
  cluster_version = var.kubernetes_version

  vpc_id     = var.tokyo_vpc_id
  subnet_ids = var.tokyo_private_subnets

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  tags = var.tags
}

###############################################################
# EKS Cluster Auth
###############################################################

data "aws_eks_cluster_auth" "seoul" {
  name       = module.eks_seoul.cluster_name
  depends_on = [module.eks_seoul]
}

data "aws_eks_cluster_auth" "tokyo" {
  provider   = aws.tokyo
  name       = module.eks_tokyo.cluster_name
  depends_on = [module.eks_tokyo]
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.ecrpublic
}

###############################################################
# IAM Role for ArgoCD Capability
###############################################################

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "argocd_capability" {
  name = "${var.project_name}-${var.env}-argocd-capability"

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

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "argocd_capability_secrets" {
  role       = aws_iam_role.argocd_capability.name
  policy_arn = "arn:aws:iam::aws:policy/AWSSecretsManagerClientReadOnlyAccess"
}

resource "aws_iam_role_policy" "argocd_capability" {
  name = "${var.project_name}-${var.env}-argocd-capability-policy"
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
        Effect   = "Allow"
        Action   = ["sso-oauth:CreateTokenWithIAM"]
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

  tags = var.tags

  depends_on = [module.eks_seoul, module.eks_blueprints_addons_seoul]
}

###############################################################
# EKS Blueprints Addons - Seoul (Hub)
###############################################################

provider "kubernetes" {
  alias                  = "seoul"
  host                   = module.eks_seoul.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_seoul.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.seoul.token
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_seoul.cluster_name, "--region", var.region_seoul]
  }
}

provider "kubernetes" {
  alias                  = "tokyo"
  host                   = module.eks_tokyo.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_tokyo.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.tokyo.token
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_tokyo.cluster_name, "--region", var.region_tokyo]
  }
}

provider "helm" {
  alias = "seoul"
  kubernetes {
    host                   = module.eks_seoul.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_seoul.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.seoul.token
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks_seoul.cluster_name]
    }
  }
}

provider "helm" {
  alias = "tokyo"
  kubernetes {
    host                   = module.eks_tokyo.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_tokyo.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.tokyo.token
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks_tokyo.cluster_name, "--region", var.region_tokyo]
    }
  }
}

provider "kubectl" {
  alias                  = "seoul"
  apply_retry_count      = 5
  host                   = module.eks_seoul.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_seoul.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_seoul.cluster_name, "--region", var.region_seoul]
  }
}

provider "kubectl" {
  alias                  = "tokyo"
  apply_retry_count      = 5
  host                   = module.eks_tokyo.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_tokyo.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_tokyo.cluster_name, "--region", var.region_tokyo]
  }
}

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

  enable_karpenter = true
  karpenter = {
    chart_version = "1.1.1"
  }
  karpenter_node = {
    iam_role_use_name_prefix = false
  }

  tags = var.tags
}

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

  enable_karpenter = true
  karpenter = {
    chart_version = "1.1.1"
  }
  karpenter_node = {
    iam_role_use_name_prefix = false
  }

  tags = var.tags
}

###############################################################
# Karpenter EC2NodeClass and NodePools
###############################################################

resource "kubectl_manifest" "ec2nodeclass_seoul" {
  provider = kubectl.seoul

  yaml_body = <<-YAML
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: t4g-nodeclass
spec:
  role: ${module.eks_blueprints_addons_seoul.karpenter.node_iam_role_name}
  amiSelectorTerms:
    - alias: al2023@latest
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${module.eks_seoul.cluster_name}
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${module.eks_seoul.cluster_name}
  tags:
    Environment: ${var.env}
YAML

  depends_on = [module.eks_blueprints_addons_seoul]
}

resource "kubectl_manifest" "nodepool_spot_seoul" {
  provider = kubectl.seoul

  yaml_body = <<-YAML
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: t4g-spot
spec:
  template:
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: t4g-nodeclass
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["arm64"]
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["t4g.small", "t4g.medium", "t4g.large"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot"]
  limits:
    cpu: ${var.node_pool_cpu_limit}
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 1m
YAML

  depends_on = [kubectl_manifest.ec2nodeclass_seoul]
}

resource "kubectl_manifest" "nodepool_ondemand_seoul" {
  provider = kubectl.seoul

  yaml_body = <<-YAML
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: t4g-ondemand
spec:
  template:
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: t4g-nodeclass
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["arm64"]
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["t4g.small", "t4g.medium", "t4g.large"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
  limits:
    cpu: ${var.node_pool_cpu_limit}
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 1m
YAML

  depends_on = [kubectl_manifest.ec2nodeclass_seoul]
}

resource "kubectl_manifest" "ec2nodeclass_tokyo" {
  provider = kubectl.tokyo

  yaml_body = <<-YAML
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: t4g-nodeclass
spec:
  role: ${module.eks_blueprints_addons_tokyo.karpenter.node_iam_role_name}
  amiSelectorTerms:
    - alias: al2023@latest
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${module.eks_tokyo.cluster_name}
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${module.eks_tokyo.cluster_name}
  tags:
    Environment: ${var.env}
YAML

  depends_on = [module.eks_blueprints_addons_tokyo]
}

resource "kubectl_manifest" "nodepool_spot_tokyo" {
  provider = kubectl.tokyo

  yaml_body = <<-YAML
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: t4g-spot
spec:
  template:
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: t4g-nodeclass
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["arm64"]
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["t4g.small", "t4g.medium", "t4g.large"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot"]
  limits:
    cpu: ${var.node_pool_cpu_limit}
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 1m
YAML

  depends_on = [kubectl_manifest.ec2nodeclass_tokyo]
}

resource "kubectl_manifest" "nodepool_ondemand_tokyo" {
  provider = kubectl.tokyo

  yaml_body = <<-YAML
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: t4g-ondemand
spec:
  template:
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: t4g-nodeclass
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["arm64"]
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["t4g.small", "t4g.medium", "t4g.large"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
  limits:
    cpu: ${var.node_pool_cpu_limit}
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 1m
YAML

  depends_on = [kubectl_manifest.ec2nodeclass_tokyo]
}
