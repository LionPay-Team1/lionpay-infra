provider "aws" {
  region = var.region_seoul
}

provider "aws" {
  alias  = "tokyo"
  region = var.region_tokyo
}

provider "aws" {
  alias  = "ecr"
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
  kubernetes {
    host                   = module.eks_admin_seoul.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_admin_seoul.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.admin_seoul.token
  }
}

provider "helm" {
  alias = "service_seoul"
  kubernetes {
    host                   = module.eks_service_seoul.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_service_seoul.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.service_seoul.token
  }
}

provider "helm" {
  alias = "service_tokyo"
  kubernetes {
    host                   = module.eks_service_tokyo.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_service_tokyo.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.service_tokyo.token
  }
}
