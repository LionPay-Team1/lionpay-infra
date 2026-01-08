###############################################################
# Route53 Zone + Records
###############################################################

resource "aws_route53_zone" "lionpay" {
  name = var.zone_name
  comment = ""

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "lionpay_apex_a" {
  zone_id = aws_route53_zone.lionpay.zone_id
  name    = var.zone_name
  type    = "A"

  lifecycle {
    prevent_destroy = true
  }

  alias {
    name                   = "d1offmun0zt2o7.cloudfront.net."
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "lionpay_apex_ns" {
  zone_id = aws_route53_zone.lionpay.zone_id
  name    = var.zone_name
  type    = "NS"
  ttl     = 172800
  records = [
    "ns-1127.awsdns-12.org.",
    "ns-1941.awsdns-50.co.uk.",
    "ns-119.awsdns-14.com.",
    "ns-740.awsdns-28.net.",
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "lionpay_apex_soa" {
  zone_id = aws_route53_zone.lionpay.zone_id
  name    = var.zone_name
  type    = "SOA"
  ttl     = 900
  records = [
    "ns-1127.awsdns-12.org. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "acm_validation_root" {
  zone_id = aws_route53_zone.lionpay.zone_id
  name    = "_1b6a80ade1807c2966c1c9ea8ab044fa.${var.zone_name}"
  type    = "CNAME"
  ttl     = 300
  records = [
    "_28a33998a7908a7212e948d456daf999.jkddzztszm.acm-validations.aws."
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "admin_a" {
  zone_id = aws_route53_zone.lionpay.zone_id
  name    = "admin.${var.zone_name}"
  type    = "A"

  lifecycle {
    prevent_destroy = true
  }

  alias {
    name                   = "d16srywbso6fsa.cloudfront.net."
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "acm_validation_admin" {
  zone_id = aws_route53_zone.lionpay.zone_id
  name    = "_052b020bb24ad451539c750cb8977279.admin.${var.zone_name}"
  type    = "CNAME"
  ttl     = 300
  records = [
    "_79194f48d0b0fc678ea221ee80d7ce21.jkddzztszm.acm-validations.aws."
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "api_a" {
  zone_id = aws_route53_zone.lionpay.zone_id
  name    = "api.${var.zone_name}"
  type    = "A"

  lifecycle {
    prevent_destroy = true
  }

  alias {
    name                   = "d20x9f76m12qrg.cloudfront.net."
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "acm_validation_api" {
  zone_id = aws_route53_zone.lionpay.zone_id
  name    = "_e63a811371a49eca18c0d50e7f0e6a16.api.${var.zone_name}"
  type    = "CNAME"
  ttl     = 300
  records = [
    "_b75ec4d96705797596b712becc2d612d.jkddzztszm.acm-validations.aws."
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "origin_api_latency_seoul" {
  zone_id = aws_route53_zone.lionpay.zone_id
  name    = "origin-api.${var.zone_name}"
  type    = "A"

  lifecycle {
    prevent_destroy = true
  }

  set_identifier = "lionpay-latency-seoul"

  latency_routing_policy {
    region = "ap-northeast-2"
  }

  alias {
    name                   = "dualstack.k8s-lionpay-lionpayi-9404506445-1666136931.ap-northeast-2.elb.amazonaws.com."
    zone_id                = "ZWKZPGTI48KDX"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "origin_api_latency_tokyo" {
  zone_id = aws_route53_zone.lionpay.zone_id
  name    = "origin-api.${var.zone_name}"
  type    = "A"

  lifecycle {
    prevent_destroy = true
  }

  set_identifier = "lionpay-latency-tokyo"

  latency_routing_policy {
    region = "ap-northeast-1"
  }

  alias {
    name                   = "dualstack.k8s-lionpay-lionpayi-af1c73a882-1629284442.ap-northeast-1.elb.amazonaws.com."
    zone_id                = "Z14GRHDCWA56QT"
    evaluate_target_health = true
  }
}
