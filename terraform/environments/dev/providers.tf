provider "aws" {
  region = var.region_seoul
}

provider "aws" {
  alias  = "tokyo"
  region = var.region_tokyo
}

provider "aws" {
  alias  = "ecrpublic"
  region = "us-east-1"
}

###############################################################
# Kubernetes Providers
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

###############################################################
# Helm Providers
###############################################################

provider "helm" {
  alias                  = "seoul"
  registry_config_path   = "${path.module}/.helm/registry.json"
  repository_config_path = "${path.module}/.helm/repositories.yaml"
  repository_cache       = "${path.module}/.helm/cache"
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
  alias                  = "tokyo"
  registry_config_path   = "${path.module}/.helm/registry.json"
  repository_config_path = "${path.module}/.helm/repositories.yaml"
  repository_cache       = "${path.module}/.helm/cache"
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

###############################################################
# Kubectl Providers
###############################################################

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
