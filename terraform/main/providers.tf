provider "aws" {
  region = var.central_region
}



provider "aws" {
  alias  = "seoul"
  region = "ap-northeast-2"
}

provider "aws" {
  alias  = "tokyo"
  region = "ap-northeast-1"
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
    args        = ["eks", "get-token", "--cluster-name", module.eks_seoul.cluster_name, "--region", "ap-northeast-2"]
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
    args        = ["eks", "get-token", "--cluster-name", module.eks_tokyo.cluster_name, "--region", "ap-northeast-1"]
  }
}

###############################################################
# Helm Providers
###############################################################

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
      args        = ["eks", "get-token", "--cluster-name", module.eks_tokyo.cluster_name, "--region", "ap-northeast-1"]
    }
  }
}
