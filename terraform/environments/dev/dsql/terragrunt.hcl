include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path   = "${dirname(find_in_parent_folders())}/environments/dev/env.hcl"
  expose = true
}

terraform {
  source = "${dirname(find_in_parent_folders())}/_envcommon/dsql"
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "eks" {
  config_path = "../eks"
}

inputs = {
  project_name = "lionpay"
  env          = include.env.locals.env

  deletion_protection_enabled = false

  # VPC dependencies
  seoul_vpc_id         = dependency.vpc.outputs.seoul_vpc_id
  seoul_vpc_cidr_block = dependency.vpc.outputs.seoul_vpc_cidr_block
  seoul_private_subnets = dependency.vpc.outputs.seoul_private_subnets
  tokyo_vpc_id         = dependency.vpc.outputs.tokyo_vpc_id
  tokyo_vpc_cidr_block = dependency.vpc.outputs.tokyo_vpc_cidr_block
  tokyo_private_subnets = dependency.vpc.outputs.tokyo_private_subnets

  # EKS dependencies (for IRSA)
  seoul_oidc_provider_arn = dependency.eks.outputs.seoul_oidc_provider_arn
  tokyo_oidc_provider_arn = dependency.eks.outputs.tokyo_oidc_provider_arn

  tags = include.env.locals.tags
}
