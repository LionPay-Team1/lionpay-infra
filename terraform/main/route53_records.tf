###############################################################
# Route53 Records - lionpay.shop
# NOTE: The Hosted Zone is managed externally (console)
###############################################################

# Data source for existing Route53 hosted zone
data "aws_route53_zone" "lionpay" {
  name = var.route53_zone_name
}

# A record for app domain -> CloudFront
# Dev:  app.dev.lionpay.shop
# Prod: lionpay.shop
resource "aws_route53_record" "app_a" {
  zone_id = data.aws_route53_zone.lionpay.zone_id
  name    = local.app_domain_name
  type    = "A"

  alias {
    name                   = module.cloudfront.app_distribution_domain_name
    zone_id                = "Z2FDTNDATAQYW2" # CloudFront hosted zone ID (global)
    evaluate_target_health = false
  }
}

# A record for admin subdomain -> CloudFront
# Dev:  admin.dev.lionpay.shop
# Prod: admin.lionpay.shop
resource "aws_route53_record" "admin_a" {
  zone_id = data.aws_route53_zone.lionpay.zone_id
  name    = local.admin_domain_name
  type    = "A"

  alias {
    name                   = module.cloudfront.admin_distribution_domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

# A record for api subdomain -> CloudFront
# Dev:  api.dev.lionpay.shop
# Prod: api.lionpay.shop
resource "aws_route53_record" "api_a" {
  zone_id = data.aws_route53_zone.lionpay.zone_id
  name    = local.api_domain_name
  type    = "A"

  alias {
    name                   = module.cloudfront.api_distribution_domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

# NOTE: origin-api latency routing records are managed by
# scripts/update-route53-alb.ps1 after ArgoCD deployment

