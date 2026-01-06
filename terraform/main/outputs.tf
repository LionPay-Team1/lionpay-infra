###############################################################
# EKS Cluster Outputs
###############################################################

output "seoul_cluster_name" {
  description = "Seoul (Hub) EKS cluster name"
  value       = module.eks_seoul.cluster_name
}

output "tokyo_cluster_name" {
  description = "Tokyo (Spoke) EKS cluster name"
  value       = module.eks_tokyo.cluster_name
}

output "seoul_cluster_endpoint" {
  description = "Seoul (Hub) EKS cluster endpoint"
  value       = module.eks_seoul.cluster_endpoint
}

output "tokyo_cluster_endpoint" {
  description = "Tokyo (Spoke) EKS cluster endpoint"
  value       = module.eks_tokyo.cluster_endpoint
}

###############################################################
# VPC Outputs
###############################################################

output "seoul_vpc_id" {
  description = "Seoul VPC ID"
  value       = module.vpc_seoul.vpc_id
}

output "tokyo_vpc_id" {
  description = "Tokyo VPC ID"
  value       = module.vpc_tokyo.vpc_id
}

output "seoul_private_subnets" {
  description = "Seoul VPC private subnet IDs"
  value       = module.vpc_seoul.private_subnets
}

output "tokyo_private_subnets" {
  description = "Tokyo VPC private subnet IDs"
  value       = module.vpc_tokyo.private_subnets
}

###############################################################
# DynamoDB Outputs
###############################################################

output "dynamodb_table_arn" {
  description = "DynamoDB global table ARN"
  value       = module.dynamodb.table_arn
}

###############################################################
# S3 Outputs
###############################################################

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = module.s3.bucket_name
}

###############################################################
# DSQL Outputs
###############################################################

output "dsql_seoul_arn" {
  description = "Aurora DSQL Seoul cluster ARN"
  value       = module.dsql_seoul.arn
}

output "dsql_tokyo_arn" {
  description = "Aurora DSQL Tokyo cluster ARN"
  value       = module.dsql_tokyo.arn
}

output "dsql_iam_role_seoul_arn" {
  description = "IAM role ARN for DSQL access from Seoul cluster"
  value       = aws_iam_role.service_account_seoul.arn
}

output "dsql_iam_role_tokyo_arn" {
  description = "IAM role ARN for DSQL access from Tokyo cluster"
  value       = aws_iam_role.service_account_tokyo.arn
}

output "dsql_seoul_id" {
  description = "Aurora DSQL Seoul cluster Identifier"
  value       = module.dsql_seoul.identifier
}

output "dsql_tokyo_id" {
  description = "Aurora DSQL Tokyo cluster Identifier"
  value       = module.dsql_tokyo.identifier
}

###############################################################
# ArgoCD Outputs
###############################################################

output "argocd_namespace" {
  description = "ArgoCD namespace in Seoul cluster"
  value       = "argocd"
}

output "argocd_server_url" {
  description = "ArgoCD server URL (available after capability is created)"
  value       = try(aws_eks_capability.argocd_seoul.configuration[0].argo_cd[0].server_url, null)
}

