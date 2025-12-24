include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path   = "${dirname(find_in_parent_folders())}/environments/dev/env.hcl"
  expose = true
}

terraform {
  source = "${dirname(find_in_parent_folders())}/_envcommon/vpc"
}

inputs = {
  project_name = "lionpay"
  env          = include.env.locals.env

  # Seoul VPC
  seoul_vpc_cidr             = include.env.locals.seoul_vpc_cidr
  seoul_azs                  = include.env.locals.seoul_azs
  seoul_private_subnet_cidrs = include.env.locals.seoul_private_subnet_cidrs
  seoul_public_subnet_cidrs  = include.env.locals.seoul_public_subnet_cidrs
  seoul_enable_nat_gateway   = true
  seoul_single_nat_gateway   = true

  # Tokyo VPC
  tokyo_vpc_cidr             = include.env.locals.tokyo_vpc_cidr
  tokyo_azs                  = include.env.locals.tokyo_azs
  tokyo_private_subnet_cidrs = include.env.locals.tokyo_private_subnet_cidrs
  tokyo_public_subnet_cidrs  = include.env.locals.tokyo_public_subnet_cidrs
  tokyo_enable_nat_gateway   = true
  tokyo_single_nat_gateway   = true

  tags = include.env.locals.tags
}
