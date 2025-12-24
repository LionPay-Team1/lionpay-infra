# Root Terragrunt configuration
# All child configurations inherit from this file

locals {
  # Project-wide settings
  project_name = "lionpay"
  region_seoul = "ap-northeast-2"
  region_tokyo = "ap-northeast-1"

  # Parse environment from path
  path_parts = split("/", path_relative_to_include())
  env        = try(local.path_parts[1], "shared")
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.region_seoul}"
}

provider "aws" {
  alias  = "tokyo"
  region = "${local.region_tokyo}"
}

provider "aws" {
  alias  = "ecrpublic"
  region = "us-east-1"
}
EOF
}

# Generate versions
generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = "~> 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.0.1"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.1"
    }
  }
}
EOF
}

# Remote state configuration (using local backend for now)
# Uncomment below for S3 backend
# remote_state {
#   backend = "s3"
#   generate = {
#     path      = "backend.tf"
#     if_exists = "overwrite_terragrunt"
#   }
#   config = {
#     bucket         = "${local.project_name}-terraform-state"
#     key            = "${path_relative_to_include()}/terraform.tfstate"
#     region         = local.region_seoul
#     encrypt        = true
#     dynamodb_table = "${local.project_name}-terraform-locks"
#   }
# }

# Common inputs for all child modules
inputs = {
  project_name = local.project_name
  region_seoul = local.region_seoul
  region_tokyo = local.region_tokyo
}
