###############################################################
# ECR Outputs
###############################################################

output "ecr_seoul_urls" {
  description = "ECR repository URLs in Seoul"
  value       = { for name, mod in module.ecr_central : name => mod.repository_url }
}

output "ecr_repository_arns" {
  description = "ECR repository ARNs in Seoul"
  value       = { for name, mod in module.ecr_central : name => mod.repository_arn }
}

output "ecr_registry_id" {
  description = "ECR registry ID (AWS account ID)"
  value       = data.aws_caller_identity.current.account_id
}
