# Prod environment configuration
locals {
  env = "prod"

  # VPC Settings - Seoul (different CIDRs from dev)
  seoul_vpc_cidr             = "10.10.0.0/16"
  seoul_azs                  = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
  seoul_private_subnet_cidrs = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  seoul_public_subnet_cidrs  = ["10.10.101.0/24", "10.10.102.0/24", "10.10.103.0/24"]

  # VPC Settings - Tokyo
  tokyo_vpc_cidr             = "10.11.0.0/16"
  tokyo_azs                  = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
  tokyo_private_subnet_cidrs = ["10.11.1.0/24", "10.11.2.0/24", "10.11.3.0/24"]
  tokyo_public_subnet_cidrs  = ["10.11.101.0/24", "10.11.102.0/24", "10.11.103.0/24"]

  # EKS Settings
  kubernetes_version = "1.34"

  # ArgoCD / IAM Identity Center
  idc_instance_arn      = "arn:aws:sso:::instance/ssoins-xxxxxxxxxxxxxxxx"  # TODO: Update this
  argocd_admin_group_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"             # TODO: Update this

  # Karpenter
  node_pool_cpu_limit = 2000  # Higher limit for production

  # DynamoDB
  dynamodb_table_name = "lionpay-prod-transactions"
  dynamodb_hash_key   = "PK"

  # S3
  s3_bucket_name = "lionpay-prod-assets"

  # Common tags
  tags = {
    Project     = "lionpay"
    Environment = "prod"
    ManagedBy   = "terragrunt"
  }
}
