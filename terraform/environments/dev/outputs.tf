output "admin_seoul_cluster_name" {
  value = module.eks_admin_seoul.cluster_name
}

output "service_seoul_cluster_name" {
  value = module.eks_service_seoul.cluster_name
}

output "service_tokyo_cluster_name" {
  value = module.eks_service_tokyo.cluster_name
}

output "admin_seoul_kubeconfig" {
  value = module.eks_admin_seoul.configure_kubectl
}

output "service_seoul_kubeconfig" {
  value = module.eks_service_seoul.configure_kubectl
}

output "service_tokyo_kubeconfig" {
  value = module.eks_service_tokyo.configure_kubectl
}

output "dynamodb_table_arn" {
  value = module.dynamodb.table_arn
}

output "dsql_cluster_identifier" {
  value = module.dsql.identifier
}

output "dsql_vpc_endpoint_service_name" {
  value = module.dsql.vpc_endpoint_service_name
}

output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "admin_seoul_vpc_id" {
  value = module.vpc_admin_seoul.vpc_id
}

output "service_seoul_vpc_id" {
  value = module.vpc_service_seoul.vpc_id
}

output "service_tokyo_vpc_id" {
  value = module.vpc_service_tokyo.vpc_id
}

output "service_seoul_private_subnets" {
  value = module.vpc_service_seoul.private_subnets
}

output "service_tokyo_private_subnets" {
  value = module.vpc_service_tokyo.private_subnets
}
