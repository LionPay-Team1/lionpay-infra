output "identifier" {
  value = aws_dsql_cluster.this.identifier
}

output "arn" {
  value = aws_dsql_cluster.this.arn
}

output "vpc_endpoint_service_name" {
  value = aws_dsql_cluster.this.vpc_endpoint_service_name
}
