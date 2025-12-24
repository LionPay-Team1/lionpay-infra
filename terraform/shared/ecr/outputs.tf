output "seoul_repository_urls" {
  value = { for k, v in aws_ecr_repository.seoul : k => v.repository_url }
}

output "tokyo_repository_urls" {
  value = { for k, v in aws_ecr_repository.tokyo : k => v.repository_url }
}
