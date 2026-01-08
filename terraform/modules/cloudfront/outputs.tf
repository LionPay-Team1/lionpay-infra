output "app_distribution_id" {
  value       = aws_cloudfront_distribution.app.id
  description = "CloudFront distribution ID for lionpay.shop."
}

output "app_distribution_domain_name" {
  value       = aws_cloudfront_distribution.app.domain_name
  description = "CloudFront domain name for lionpay.shop."
}

output "admin_distribution_id" {
  value       = aws_cloudfront_distribution.admin.id
  description = "CloudFront distribution ID for admin.lionpay.shop."
}

output "admin_distribution_domain_name" {
  value       = aws_cloudfront_distribution.admin.domain_name
  description = "CloudFront domain name for admin.lionpay.shop."
}

output "api_distribution_id" {
  value       = aws_cloudfront_distribution.api.id
  description = "CloudFront distribution ID for api.lionpay.shop."
}

output "api_distribution_domain_name" {
  value       = aws_cloudfront_distribution.api.domain_name
  description = "CloudFront domain name for api.lionpay.shop."
}

output "oac_id" {
  value       = aws_cloudfront_origin_access_control.frontend.id
  description = "Origin Access Control ID shared by frontend distributions."
}
