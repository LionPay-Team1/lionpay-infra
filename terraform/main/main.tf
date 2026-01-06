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
# Locals
###############################################################

locals {
  name_prefix = "${var.project_name}-${var.env}"

  # Cluster names - Seoul is Hub (ArgoCD), Tokyo is Spoke
  seoul_cluster_name = "${local.name_prefix}-seoul"
  tokyo_cluster_name = "${local.name_prefix}-tokyo"

  dynamodb_hash_key  = "pk"
  dynamodb_range_key = "sk"
  jwt_issuer         = "lionpay-auth"
  jwt_audiences      = "lionpay-app,lionpay-management"

  tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.env
  })
}
