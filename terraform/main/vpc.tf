###############################################################
# VPC Modules - Seoul (Hub) & Tokyo (Spoke)
###############################################################

module "vpc_seoul" {
  source = "../modules/vpc"

  name                 = "${local.name_prefix}-vpc-seoul"
  cidr                 = var.seoul_vpc_cidr
  azs                  = var.seoul_azs
  private_subnet_cidrs = var.seoul_private_subnet_cidrs
  public_subnet_cidrs  = var.seoul_public_subnet_cidrs
  enable_nat_gateway   = true
  single_nat_gateway   = true

  # Karpenter discovery tag for subnets
  cluster_name = local.seoul_cluster_name

  enable_dynamodb_endpoint = true
  tags                     = local.tags
}

module "vpc_tokyo" {
  source = "../modules/vpc"
  providers = {
    aws = aws.tokyo
  }

  name                 = "${local.name_prefix}-vpc-tokyo"
  cidr                 = var.tokyo_vpc_cidr
  azs                  = var.tokyo_azs
  private_subnet_cidrs = var.tokyo_private_subnet_cidrs
  public_subnet_cidrs  = var.tokyo_public_subnet_cidrs
  enable_nat_gateway   = true
  single_nat_gateway   = true

  # Karpenter discovery tag for subnets
  cluster_name = local.tokyo_cluster_name

  enable_dynamodb_endpoint = true
  tags                     = local.tags
}
