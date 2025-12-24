# Seoul EKS outputs
output "seoul_cluster_name" {
  value = module.eks_seoul.cluster_name
}

output "seoul_cluster_endpoint" {
  value = module.eks_seoul.cluster_endpoint
}

output "seoul_cluster_certificate_authority_data" {
  value = module.eks_seoul.cluster_certificate_authority_data
}

output "seoul_oidc_provider_arn" {
  value = module.eks_seoul.oidc_provider_arn
}

output "seoul_karpenter_instance_profile_name" {
  value = module.eks_blueprints_addons_seoul.karpenter.node_instance_profile_name
}

# Tokyo EKS outputs
output "tokyo_cluster_name" {
  value = module.eks_tokyo.cluster_name
}

output "tokyo_cluster_endpoint" {
  value = module.eks_tokyo.cluster_endpoint
}

output "tokyo_cluster_certificate_authority_data" {
  value = module.eks_tokyo.cluster_certificate_authority_data
}

output "tokyo_oidc_provider_arn" {
  value = module.eks_tokyo.oidc_provider_arn
}

output "tokyo_karpenter_instance_profile_name" {
  value = module.eks_blueprints_addons_tokyo.karpenter.node_instance_profile_name
}

# ArgoCD outputs
output "argocd_namespace" {
  value = "argocd"
}

output "argocd_server_url" {
  value = try(aws_eks_capability.argocd_seoul.configuration[0].argo_cd[0].server_url, null)
}
