###############################################################
# CloudFront (API + Frontend)
###############################################################

# Environment-based domain naming:
# - Dev:  app.dev.lionpay.shop, admin.dev.lionpay.shop, api.dev.lionpay.shop
# - Prod: lionpay.shop, admin.lionpay.shop, api.lionpay.shop

locals {
  # Base domain varies by environment
  base_domain = var.env == "prod" ? var.route53_zone_name : "${var.env}.${var.route53_zone_name}"

  # Domain names for CloudFront
  app_domain_name   = var.env == "prod" ? var.route53_zone_name : "app.${local.base_domain}"
  admin_domain_name = "admin.${local.base_domain}"
  api_domain_name   = "api.${local.base_domain}"

  # Origin domain for ALB (latency routing)
  origin_api_domain = "origin-api.${local.base_domain}"
}

module "cloudfront" {
  source = "../modules/cloudfront"

  s3_bucket_id                   = module.frontend_s3.bucket_id
  s3_bucket_arn                  = module.frontend_s3.bucket_arn
  s3_bucket_regional_domain_name = module.frontend_s3.bucket_regional_domain_name

  app_domain_name   = local.app_domain_name
  admin_domain_name = local.admin_domain_name
  api_domain_name   = local.api_domain_name

  api_origin_domain_name = local.origin_api_domain

  app_acm_arn   = var.cloudfront_acm_arn
  admin_acm_arn = var.cloudfront_acm_arn
  api_acm_arn   = var.cloudfront_acm_arn

  oac_name        = var.cloudfront_oac_name
  oac_description = var.cloudfront_oac_description
  price_class     = var.cloudfront_price_class

  app_tags   = var.cloudfront_app_tags
  admin_tags = var.cloudfront_admin_tags
  api_tags   = var.cloudfront_api_tags

  app_s3_origin_id_override      = var.cloudfront_app_s3_origin_id_override
  admin_s3_origin_id_override    = var.cloudfront_admin_s3_origin_id_override
  api_default_origin_id_override = var.cloudfront_api_default_origin_id_override
  api_ordered_origin_id_override = var.cloudfront_api_ordered_origin_id_override
  api_default_root_object        = var.cloudfront_api_default_root_object

  app_web_acl_id   = var.enable_waf ? aws_wafv2_web_acl.cloudfront[0].arn : null
  admin_web_acl_id = var.enable_waf ? aws_wafv2_web_acl.cloudfront[0].arn : null
  api_web_acl_id   = var.enable_waf ? aws_wafv2_web_acl.cloudfront[0].arn : null
}

