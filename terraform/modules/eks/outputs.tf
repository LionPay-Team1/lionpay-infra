output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = module.eks.cluster_version
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider" {
  description = "OIDC provider URL without https:// prefix (for IAM trust policy conditions)"
  value       = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
}

output "node_security_group_id" {
  description = "Security group ID for the nodes"
  value       = module.eks.node_security_group_id
}

output "cluster_primary_security_group_id" {
  description = "Primary security group ID for the cluster"
  value       = module.eks.cluster_primary_security_group_id
}

###############################################################
# Karpenter Outputs
###############################################################

output "karpenter_node_iam_role_name" {
  description = "Name of the IAM role for Karpenter nodes"
  value       = aws_iam_role.karpenter_node_role.name
}

output "karpenter_node_iam_role_arn" {
  description = "ARN of the IAM role for Karpenter nodes"
  value       = aws_iam_role.karpenter_node_role.arn
}

output "karpenter_instance_profile_name" {
  description = "Name of the instance profile for Karpenter nodes"
  value       = aws_iam_instance_profile.karpenter.name
}

output "karpenter_instance_profile_arn" {
  description = "ARN of the instance profile for Karpenter nodes"
  value       = aws_iam_instance_profile.karpenter.arn
}

output "load_balancer_controller_iam_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller"
  value       = module.load_balancer_controller_iam_role.iam_role_arn
}
