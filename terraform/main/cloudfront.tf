###############################################################
# CloudFront (API + Frontend)
###############################################################

module "cloudfront" {
  source = "../modules/cloudfront"

  s3_bucket_name = var.cloudfront_frontend_bucket_name

  app_domain_name   = "lionpay.shop"
  admin_domain_name = "admin.lionpay.shop"
  api_domain_name   = "api.lionpay.shop"

  app_backend_origin_domain_name = var.cloudfront_app_backend_origin_domain_name
  api_origin_domain_name         = var.cloudfront_api_origin_domain_name

  app_acm_arn   = var.cloudfront_app_acm_arn
  admin_acm_arn = var.cloudfront_admin_acm_arn
  api_acm_arn   = var.cloudfront_api_acm_arn

  oac_name        = var.cloudfront_oac_name
  oac_description = var.cloudfront_oac_description
  price_class = var.cloudfront_price_class

  app_tags   = var.cloudfront_app_tags
  admin_tags = var.cloudfront_admin_tags
  api_tags   = var.cloudfront_api_tags

  app_s3_origin_id_override       = var.cloudfront_app_s3_origin_id_override
  admin_s3_origin_id_override     = var.cloudfront_admin_s3_origin_id_override
  app_backend_origin_id_override  = var.cloudfront_app_backend_origin_id_override
  api_default_origin_id_override  = var.cloudfront_api_default_origin_id_override
  api_ordered_origin_id_override  = var.cloudfront_api_ordered_origin_id_override
  api_default_root_object         = var.cloudfront_api_default_root_object

  app_web_acl_id   = var.cloudfront_app_web_acl_id
  admin_web_acl_id = var.cloudfront_admin_web_acl_id
  api_web_acl_id   = var.cloudfront_api_web_acl_id
}
