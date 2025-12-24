output "identifier" {
  description = "DSQL cluster identifier"
  value       = aws_dsql_cluster.this.identifier
}

output "arn" {
  description = "DSQL cluster ARN"
  value       = aws_dsql_cluster.this.arn
}

output "vpc_endpoint_service_name" {
  description = "VPC endpoint service name for the DSQL cluster"
  value       = aws_dsql_cluster.this.vpc_endpoint_service_name
}
