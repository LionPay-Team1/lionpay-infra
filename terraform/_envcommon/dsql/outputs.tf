output "dsql_seoul_arn" {
  value = aws_dsql_cluster.seoul.arn
}

output "dsql_tokyo_arn" {
  value = aws_dsql_cluster.tokyo.arn
}

output "dsql_iam_role_seoul_arn" {
  value = aws_iam_role.service_account_seoul.arn
}

output "dsql_iam_role_tokyo_arn" {
  value = aws_iam_role.service_account_tokyo.arn
}
