output "ecr_seoul_urls" {
  value = { for name, mod in module.ecr_seoul : name => mod.repository_url }
}

output "ecr_tokyo_urls" {
  value = { for name, mod in module.ecr_tokyo : name => mod.repository_url }
}
