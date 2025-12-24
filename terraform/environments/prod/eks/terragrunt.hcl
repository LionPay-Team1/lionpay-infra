include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path   = "${dirname(find_in_parent_folders())}/environments/prod/env.hcl"
  expose = true
}

terraform {
  source = "${dirname(find_in_parent_folders())}/_envcommon/eks"
}

dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  project_name = "lionpay"
  env          = include.env.locals.env

  # VPC dependencies
  seoul_vpc_id          = dependency.vpc.outputs.seoul_vpc_id
  seoul_private_subnets = dependency.vpc.outputs.seoul_private_subnets
  tokyo_vpc_id          = dependency.vpc.outputs.tokyo_vpc_id
  tokyo_private_subnets = dependency.vpc.outputs.tokyo_private_subnets

  # EKS Settings
  kubernetes_version = include.env.locals.kubernetes_version

  # ArgoCD
  idc_instance_arn      = include.env.locals.idc_instance_arn
  argocd_admin_group_id = include.env.locals.argocd_admin_group_id

  # Karpenter
  node_pool_cpu_limit = include.env.locals.node_pool_cpu_limit

  tags = include.env.locals.tags
}
