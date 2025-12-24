###############################################################
# VPC Resources (Seoul & Tokyo)
###############################################################

module "vpc_seoul" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-${var.env}-vpc-seoul"
  cidr = var.seoul_vpc_cidr

  azs             = var.seoul_azs
  private_subnets = var.seoul_private_subnet_cidrs
  public_subnets  = var.seoul_public_subnet_cidrs

  enable_nat_gateway = var.seoul_enable_nat_gateway
  single_nat_gateway = var.seoul_single_nat_gateway

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = "${var.project_name}-${var.env}-seoul"
  }

  tags = var.tags
}

module "vpc_tokyo" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  providers = {
    aws = aws.tokyo
  }

  name = "${var.project_name}-${var.env}-vpc-tokyo"
  cidr = var.tokyo_vpc_cidr

  azs             = var.tokyo_azs
  private_subnets = var.tokyo_private_subnet_cidrs
  public_subnets  = var.tokyo_public_subnet_cidrs

  enable_nat_gateway = var.tokyo_enable_nat_gateway
  single_nat_gateway = var.tokyo_single_nat_gateway

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = "${var.project_name}-${var.env}-tokyo"
  }

  tags = var.tags
}

###############################################################
# DynamoDB VPC Endpoints
###############################################################

resource "aws_vpc_endpoint" "dynamodb_seoul" {
  vpc_id            = module.vpc_seoul.vpc_id
  service_name      = "com.amazonaws.${var.region_seoul}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc_seoul.private_route_table_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.env}-dynamodb-vpce-seoul"
  })
}

resource "aws_vpc_endpoint" "dynamodb_tokyo" {
  provider          = aws.tokyo
  vpc_id            = module.vpc_tokyo.vpc_id
  service_name      = "com.amazonaws.${var.region_tokyo}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc_tokyo.private_route_table_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.env}-dynamodb-vpce-tokyo"
  })
}
