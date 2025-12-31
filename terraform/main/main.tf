terraform {
  required_version = "~> 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.27.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.0.1"
    }

  }
}

###############################################################
# Locals and Data Sources
###############################################################

locals {
  name_prefix = "${var.project_name}-${var.env}"

  # Cluster names - Seoul is Hub (ArgoCD), Tokyo is Spoke
  seoul_cluster_name = "${local.name_prefix}-seoul"
  tokyo_cluster_name = "${local.name_prefix}-tokyo"

  tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.env
  })
}

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

resource "kubernetes_namespace_v1" "monitoring_seoul" {
  provider = kubernetes.seoul  

  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_namespace_v1" "monitoring_tokyo" {
  provider = kubernetes.tokyo

  metadata {
    name = "monitoring"
  }
}


module "monitoring" {
  source = "./monitoring"

  depends_on = [
    kubernetes_namespace_v1.monitoring_seoul,
    kubernetes_namespace_v1.monitoring_tokyo
  ]

  providers = {
    helm.seoul       = helm.seoul
    kubernetes.seoul = kubernetes.seoul
    helm.tokyo       = helm.tokyo
    kubernetes.tokyo = kubernetes.tokyo
  }

  metrics_username = var.metrics_username
  metrics_password = var.metrics_password
  logs_username    = var.logs_username
  logs_password    = var.logs_password
  traces_username  = var.traces_username
  traces_password  = var.traces_password
}

