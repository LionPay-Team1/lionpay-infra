# Dev environment configuration
locals {
  env = "dev"

  # VPC Settings - Seoul
  seoul_vpc_cidr             = "10.0.0.0/16"
  seoul_azs                  = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
  seoul_private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  seoul_public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  # VPC Settings - Tokyo
  tokyo_vpc_cidr             = "10.1.0.0/16"
  tokyo_azs                  = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
  tokyo_private_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  tokyo_public_subnet_cidrs  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]

  # EKS Settings
  kubernetes_version = "1.34"

  # ArgoCD / IAM Identity Center
  idc_instance_arn      = "arn:aws:sso:::instance/ssoins-xxxxxxxxxxxxxxxx"  # TODO: Update this
  argocd_admin_group_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"             # TODO: Update this

  # Karpenter
  node_pool_cpu_limit = 1000

  # DynamoDB
  dynamodb_table_name = "lionpay-dev-transactions"
  dynamodb_hash_key   = "PK"

  # S3
  s3_bucket_name = "lionpay-dev-assets"

  # Common tags
  tags = {
    Project     = "lionpay"
    Environment = "dev"
    ManagedBy   = "terragrunt"
  }
}
