project_name   = "lionpay"
env            = "dev"
central_region = "ap-northeast-2"

seoul_vpc_cidr             = "10.13.0.0/16"
seoul_azs                  = ["ap-northeast-2a", "ap-northeast-2b"]
seoul_private_subnet_cidrs = ["10.13.0.0/20", "10.13.16.0/20"]
seoul_public_subnet_cidrs  = ["10.13.48.0/24", "10.13.49.0/24"]

tokyo_vpc_cidr             = "10.22.0.0/16"
tokyo_azs                  = ["ap-northeast-1a", "ap-northeast-1c"]
tokyo_private_subnet_cidrs = ["10.22.0.0/20", "10.22.16.0/20"]
tokyo_public_subnet_cidrs  = ["10.22.48.0/24", "10.22.49.0/24"]

dynamodb_table_name = "LionpayAuthDev"
dynamodb_hash_key   = "pk"

s3_bucket_name = "lionpay-artifacts-dev"

# ArgoCD Capability (AWS Identity Center)
idc_instance_arn      = "arn:aws:sso:::instance/ssoins-72303d25a51b8abe"
argocd_admin_group_id = "74689dac-9021-7043-6b98-b2ecbf19344c"

# Managed Node Group (Karpenter Controller & Addons)
mng_instance_types = ["t4g.medium"]
mng_min_size       = 1
mng_max_size       = 4
mng_desired_size   = 2
