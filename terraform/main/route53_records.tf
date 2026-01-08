###############################################################
# Route53 - lionpay.shop
###############################################################

module "route53" {
  source = "../modules/route53"

  zone_name = var.route53_zone_name

  # CloudFront distribution domain names (from cloudfront module)
  app_cloudfront_domain_name   = module.cloudfront.app_distribution_domain_name
  admin_cloudfront_domain_name = module.cloudfront.admin_distribution_domain_name
  api_cloudfront_domain_name   = module.cloudfront.api_distribution_domain_name

  # NOTE: origin-api latency routing records are managed by
  # scripts/update-route53-alb.ps1 after ArgoCD deployment
}
