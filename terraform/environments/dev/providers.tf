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

provider "kubernetes" {
  alias                  = "admin_seoul"
  host                   = module.eks_admin_seoul.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_admin_seoul.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.admin_seoul.token
}

provider "kubernetes" {
  alias                  = "service_seoul"
  host                   = module.eks_service_seoul.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_service_seoul.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.service_seoul.token
}

provider "kubernetes" {
  alias                  = "service_tokyo"
  host                   = module.eks_service_tokyo.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_service_tokyo.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.service_tokyo.token
}

provider "helm" {
  alias = "admin_seoul"
  registry_config_path   = "${path.module}/.helm/registry.json"
  repository_config_path = "${path.module}/.helm/repositories.yaml"
  repository_cache       = "${path.module}/.helm/cache"
  kubernetes {
    host                   = module.eks_admin_seoul.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_admin_seoul.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.admin_seoul.token
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks_admin_seoul.cluster_name]
    }
  }
}

provider "helm" {
  alias = "service_seoul"
  registry_config_path   = "${path.module}/.helm/registry.json"
  repository_config_path = "${path.module}/.helm/repositories.yaml"
  repository_cache       = "${path.module}/.helm/cache"
  kubernetes {
    host                   = module.eks_service_seoul.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_service_seoul.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.service_seoul.token
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks_service_seoul.cluster_name]
    }
  }
}

provider "helm" {
  alias = "service_tokyo"
  registry_config_path   = "${path.module}/.helm/registry.json"
  repository_config_path = "${path.module}/.helm/repositories.yaml"
  repository_cache       = "${path.module}/.helm/cache"
  kubernetes {
    host                   = module.eks_service_tokyo.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_service_tokyo.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.service_tokyo.token
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks_service_tokyo.cluster_name]
    }
  }
}
