# Seoul VPC outputs
output "seoul_vpc_id" {
  value = module.vpc_seoul.vpc_id
}

output "seoul_vpc_cidr_block" {
  value = module.vpc_seoul.vpc_cidr_block
}

output "seoul_private_subnets" {
  value = module.vpc_seoul.private_subnets
}

output "seoul_public_subnets" {
  value = module.vpc_seoul.public_subnets
}

# Tokyo VPC outputs
output "tokyo_vpc_id" {
  value = module.vpc_tokyo.vpc_id
}

output "tokyo_vpc_cidr_block" {
  value = module.vpc_tokyo.vpc_cidr_block
}

output "tokyo_private_subnets" {
  value = module.vpc_tokyo.private_subnets
}

output "tokyo_public_subnets" {
  value = module.vpc_tokyo.public_subnets
}
