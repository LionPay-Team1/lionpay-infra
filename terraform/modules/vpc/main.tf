module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.1"

  name = var.name
  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = var.karpenter_discovery_tag
  }

  tags = var.tags
}

resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_dynamodb_endpoint ? 1 : 0

  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids

  tags = merge(var.tags, {
    Name = "${var.name}-dynamodb-endpoint"
  })
}

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids

  tags = merge(var.tags, {
    Name = "${var.name}-s3-endpoint"
  })
}

data "aws_region" "current" {}
