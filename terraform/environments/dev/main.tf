locals {
  name_prefix = "${var.project_name}-${var.env}"

  admin_seoul_cluster_name  = coalesce(var.admin_seoul_cluster_name, "${local.name_prefix}-admin-seoul")
  service_seoul_cluster_name = coalesce(var.service_seoul_cluster_name, "${local.name_prefix}-service-seoul")
  service_tokyo_cluster_name = coalesce(var.service_tokyo_cluster_name, "${local.name_prefix}-service-tokyo")

  tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.env
  })

}

data "aws_eks_cluster_auth" "admin_seoul" {
  name = module.eks_admin_seoul.cluster_name
}

data "aws_eks_cluster_auth" "service_seoul" {
  name = module.eks_service_seoul.cluster_name
}

data "aws_eks_cluster_auth" "service_tokyo" {
  provider = aws.tokyo
  name     = module.eks_service_tokyo.cluster_name
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.ecrpublic
}

locals {
  ecrpublic_auth     = base64decode(data.aws_ecrpublic_authorization_token.token.authorization_token)
  ecrpublic_password = split(":", local.ecrpublic_auth)[1]
}

module "vpc_admin_seoul" {
  source = "../../modules/network"

  name                  = "${local.name_prefix}-admin-vpc-seoul"
  cidr                  = var.admin_seoul_vpc_cidr
  azs                   = var.admin_seoul_azs
  private_subnet_cidrs  = var.admin_seoul_private_subnet_cidrs
  public_subnet_cidrs   = var.admin_seoul_public_subnet_cidrs
  enable_nat_gateway    = var.admin_seoul_enable_nat_gateway
  single_nat_gateway    = var.admin_seoul_single_nat_gateway
  karpenter_discovery_tag = local.admin_seoul_cluster_name
  tags                  = local.tags
}

module "vpc_service_seoul" {
  source = "../../modules/network"

  name                  = "${local.name_prefix}-service-vpc-seoul"
  cidr                  = var.service_seoul_vpc_cidr
  azs                   = var.service_seoul_azs
  private_subnet_cidrs  = var.service_seoul_private_subnet_cidrs
  public_subnet_cidrs   = var.service_seoul_public_subnet_cidrs
  enable_nat_gateway    = var.service_seoul_enable_nat_gateway
  single_nat_gateway    = var.service_seoul_single_nat_gateway
  karpenter_discovery_tag = local.service_seoul_cluster_name
  tags                  = local.tags
}

module "vpc_service_tokyo" {
  source = "../../modules/network"
  providers = {
    aws = aws.tokyo
  }

  name                  = "${local.name_prefix}-service-vpc-tokyo"
  cidr                  = var.service_tokyo_vpc_cidr
  azs                   = var.service_tokyo_azs
  private_subnet_cidrs  = var.service_tokyo_private_subnet_cidrs
  public_subnet_cidrs   = var.service_tokyo_public_subnet_cidrs
  enable_nat_gateway    = var.service_tokyo_enable_nat_gateway
  single_nat_gateway    = var.service_tokyo_single_nat_gateway
  karpenter_discovery_tag = local.service_tokyo_cluster_name
  tags                  = local.tags
}

module "eks_admin_seoul" {
  source = "../../modules/eks"

  cluster_name                    = local.admin_seoul_cluster_name
  kubernetes_version              = var.kubernetes_version
  aws_region                      = var.region_seoul
  vpc_id                          = module.vpc_admin_seoul.vpc_id
  private_subnet_ids              = module.vpc_admin_seoul.private_subnets
  enable_karpenter                = var.admin_enable_karpenter
  karpenter_discovery_tag         = local.admin_seoul_cluster_name
  karpenter_controller_ami_type   = var.karpenter_controller_ami_type
  karpenter_controller_instance_types = var.karpenter_controller_instance_types
  karpenter_controller_capacity_type  = var.karpenter_controller_capacity_type
  karpenter_controller_min_size   = var.karpenter_controller_min_size
  karpenter_controller_max_size   = var.karpenter_controller_max_size
  karpenter_controller_desired_size = var.karpenter_controller_desired_size
  tags                            = local.tags
}

module "eks_service_seoul" {
  source = "../../modules/eks"

  cluster_name                    = local.service_seoul_cluster_name
  kubernetes_version              = var.kubernetes_version
  aws_region                      = var.region_seoul
  vpc_id                          = module.vpc_service_seoul.vpc_id
  private_subnet_ids              = module.vpc_service_seoul.private_subnets
  enable_karpenter                = var.service_seoul_enable_karpenter
  karpenter_discovery_tag         = local.service_seoul_cluster_name
  karpenter_controller_ami_type   = var.karpenter_controller_ami_type
  karpenter_controller_instance_types = var.karpenter_controller_instance_types
  karpenter_controller_capacity_type  = var.karpenter_controller_capacity_type
  karpenter_controller_min_size   = var.karpenter_controller_min_size
  karpenter_controller_max_size   = var.karpenter_controller_max_size
  karpenter_controller_desired_size = var.karpenter_controller_desired_size
  tags                            = local.tags
}

module "eks_service_tokyo" {
  source = "../../modules/eks"
  providers = {
    aws = aws.tokyo
  }

  cluster_name                    = local.service_tokyo_cluster_name
  kubernetes_version              = var.kubernetes_version
  aws_region                      = var.region_tokyo
  vpc_id                          = module.vpc_service_tokyo.vpc_id
  private_subnet_ids              = module.vpc_service_tokyo.private_subnets
  enable_karpenter                = var.service_tokyo_enable_karpenter
  karpenter_discovery_tag         = local.service_tokyo_cluster_name
  karpenter_controller_ami_type   = var.karpenter_controller_ami_type
  karpenter_controller_instance_types = var.karpenter_controller_instance_types
  karpenter_controller_capacity_type  = var.karpenter_controller_capacity_type
  karpenter_controller_min_size   = var.karpenter_controller_min_size
  karpenter_controller_max_size   = var.karpenter_controller_max_size
  karpenter_controller_desired_size = var.karpenter_controller_desired_size
  tags                            = local.tags
}

module "eks_blueprints_addons_admin_seoul" {
  source = "aws-ia/eks-blueprints-addons/aws"
  providers = {
    aws        = aws
    helm       = helm.admin_seoul
    kubernetes = kubernetes.admin_seoul
  }

  cluster_name      = module.eks_admin_seoul.cluster_name
  cluster_endpoint  = module.eks_admin_seoul.cluster_endpoint
  cluster_version   = module.eks_admin_seoul.cluster_version
  oidc_provider_arn = module.eks_admin_seoul.oidc_provider_arn

  enable_metrics_server     = true

  tags = local.tags
}

module "eks_blueprints_addons_service_seoul" {
  source = "aws-ia/eks-blueprints-addons/aws"
  providers = {
    aws        = aws
    helm       = helm.service_seoul
    kubernetes = kubernetes.service_seoul
  }

  cluster_name      = module.eks_service_seoul.cluster_name
  cluster_endpoint  = module.eks_service_seoul.cluster_endpoint
  cluster_version   = module.eks_service_seoul.cluster_version
  oidc_provider_arn = module.eks_service_seoul.oidc_provider_arn

  enable_metrics_server     = true

  tags = local.tags
}

module "eks_blueprints_addons_service_tokyo" {
  source = "aws-ia/eks-blueprints-addons/aws"
  providers = {
    aws        = aws.tokyo
    helm       = helm.service_tokyo
    kubernetes = kubernetes.service_tokyo
  }

  cluster_name      = module.eks_service_tokyo.cluster_name
  cluster_endpoint  = module.eks_service_tokyo.cluster_endpoint
  cluster_version   = module.eks_service_tokyo.cluster_version
  oidc_provider_arn = module.eks_service_tokyo.oidc_provider_arn

  enable_metrics_server     = true

  tags = local.tags
}

module "karpenter_admin_seoul" {
  count  = var.admin_enable_karpenter ? 1 : 0
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  source = "../../modules/karpenter"
  providers = {
    aws        = aws
    helm       = helm.admin_seoul
    kubernetes = kubernetes.admin_seoul
  }

  cluster_name        = module.eks_admin_seoul.cluster_name
  cluster_endpoint    = module.eks_admin_seoul.cluster_endpoint
  node_iam_role_name  = local.admin_seoul_cluster_name
  node_class_name     = var.karpenter_node_class_name
  node_pool_name      = var.karpenter_node_pool_name
  ami_alias           = var.karpenter_ami_alias
  discovery_tag       = local.admin_seoul_cluster_name
  instance_categories = var.karpenter_instance_categories
  instance_cpus       = var.karpenter_instance_cpus
  instance_generations = var.karpenter_instance_generations
  capacity_types      = var.karpenter_capacity_types
  architectures       = var.karpenter_architectures
  node_pool_cpu_limit = var.karpenter_node_pool_cpu_limit
  consolidation_policy = var.karpenter_consolidation_policy
  consolidate_after   = var.karpenter_consolidate_after
  chart_version       = var.karpenter_chart_version
  tags                = local.tags
}

# module "karpenter_service_seoul" {
#   count  = var.service_seoul_enable_karpenter ? 1 : 0
#   source = "../../modules/karpenter"
#   repository_username = data.aws_ecrpublic_authorization_token.token.user_name
#   repository_password = data.aws_ecrpublic_authorization_token.token.password
#   providers = {
#     aws        = aws
#     helm       = helm.service_seoul
#     kubernetes = kubernetes.service_seoul
#   }

#   cluster_name        = module.eks_service_seoul.cluster_name
#   cluster_endpoint    = module.eks_service_seoul.cluster_endpoint
#   node_iam_role_name  = local.service_seoul_cluster_name
#   node_class_name     = var.karpenter_node_class_name
#   node_pool_name      = var.karpenter_node_pool_name
#   ami_alias           = var.karpenter_ami_alias
#   discovery_tag       = local.service_seoul_cluster_name
#   instance_categories = var.karpenter_instance_categories
#   instance_cpus       = var.karpenter_instance_cpus
#   instance_generations = var.karpenter_instance_generations
#   capacity_types      = var.karpenter_capacity_types
#   architectures       = var.karpenter_architectures
#   node_pool_cpu_limit = var.karpenter_node_pool_cpu_limit
#   consolidation_policy = var.karpenter_consolidation_policy
#   consolidate_after   = var.karpenter_consolidate_after
#   chart_version       = var.karpenter_chart_version
#   tags                = local.tags
# }

# module "karpenter_service_tokyo" {
#   count  = var.service_tokyo_enable_karpenter ? 1 : 0
#   source = "../../modules/karpenter"
#   repository_username = data.aws_ecrpublic_authorization_token.token.user_name
#   repository_password = data.aws_ecrpublic_authorization_token.token.password
#   providers = {
#     aws        = aws.tokyo
#     helm       = helm.service_tokyo
#     kubernetes = kubernetes.service_tokyo
#   }

#   cluster_name        = module.eks_service_tokyo.cluster_name
#   cluster_endpoint    = module.eks_service_tokyo.cluster_endpoint
#   node_iam_role_name  = local.service_tokyo_cluster_name
#   node_class_name     = var.karpenter_node_class_name
#   node_pool_name      = var.karpenter_node_pool_name
#   ami_alias           = var.karpenter_ami_alias
#   discovery_tag       = local.service_tokyo_cluster_name
#   instance_categories = var.karpenter_instance_categories
#   instance_cpus       = var.karpenter_instance_cpus
#   instance_generations = var.karpenter_instance_generations
#   capacity_types      = var.karpenter_capacity_types
#   architectures       = var.karpenter_architectures
#   node_pool_cpu_limit = var.karpenter_node_pool_cpu_limit
#   consolidation_policy = var.karpenter_consolidation_policy
#   consolidate_after   = var.karpenter_consolidate_after
#   chart_version       = var.karpenter_chart_version
#   tags                = local.tags
# }

module "dynamodb" {
  source = "../../modules/dynamodb"

  table_name              = var.dynamodb_table_name
  billing_mode            = var.dynamodb_billing_mode
  hash_key                = var.dynamodb_hash_key
  hash_key_type           = var.dynamodb_hash_key_type
  range_key               = var.dynamodb_range_key
  range_key_type          = var.dynamodb_range_key_type
  point_in_time_recovery  = var.dynamodb_point_in_time_recovery
  deletion_protection     = var.dynamodb_deletion_protection
  tags                    = local.tags
}

module "dsql" {
  source = "../../modules/dsql"

  deletion_protection_enabled = var.dsql_deletion_protection_enabled
  force_destroy               = var.dsql_force_destroy
  kms_encryption_key          = var.dsql_kms_encryption_key
  witness_region              = var.dsql_witness_region
  region                      = var.dsql_region
  tags                        = local.tags
}

module "s3" {
  source = "../../modules/s3"

  bucket_name         = var.s3_bucket_name
  versioning_enabled  = var.s3_versioning_enabled
  sse_algorithm       = var.s3_sse_algorithm
  tags                = local.tags
}
