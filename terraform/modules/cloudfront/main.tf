# S3 bucket info is passed directly from parent module to avoid data source lookup issues

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = var.oac_name
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

locals {
  allowed_methods_all      = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
  allowed_methods_get_head = ["GET", "HEAD"]
  cached_methods_basic     = ["GET", "HEAD"]

  origin_ids = {
    app_s3   = coalesce(var.app_s3_origin_id_override, "frontend-app")
    admin_s3 = coalesce(var.admin_s3_origin_id_override, "frontend-admin")
    api_def  = coalesce(var.api_default_origin_id_override, "api-origin-default")
    api_api  = coalesce(var.api_ordered_origin_id_override, "api-origin-latency")
  }
}

resource "aws_cloudfront_distribution" "app" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  http_version        = "http1.1"
  price_class         = var.price_class
  aliases             = [var.app_domain_name]
  web_acl_id          = var.app_web_acl_id

  origin {
    domain_name              = var.s3_bucket_regional_domain_name
    origin_id                = local.origin_ids.app_s3
    origin_path              = "/app"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  default_cache_behavior {
    target_origin_id       = local.origin_ids.app_s3
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = local.allowed_methods_all
    cached_methods         = local.cached_methods_basic
    compress               = true

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.app_acm_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = var.app_tags
}

resource "aws_cloudfront_distribution" "admin" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  http_version        = "http2"
  price_class         = var.price_class
  aliases             = [var.admin_domain_name]
  web_acl_id          = var.admin_web_acl_id

  origin {
    domain_name              = var.s3_bucket_regional_domain_name
    origin_id                = local.origin_ids.admin_s3
    origin_path              = "/management"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  default_cache_behavior {
    target_origin_id       = local.origin_ids.admin_s3
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = local.allowed_methods_get_head
    cached_methods         = local.cached_methods_basic
    compress               = true

    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.admin_acm_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = var.admin_tags
}

resource "aws_cloudfront_distribution" "api" {
  enabled         = true
  is_ipv6_enabled = true
  http_version    = "http2"
  price_class     = var.price_class
  aliases         = [var.api_domain_name]
  web_acl_id      = var.api_web_acl_id

  default_root_object = var.api_default_root_object

  origin {
    domain_name = var.api_origin_domain_name
    origin_id   = local.origin_ids.api_def

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      ip_address_type        = "ipv4"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  origin {
    domain_name = var.api_origin_domain_name
    origin_id   = local.origin_ids.api_api

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      ip_address_type        = "ipv4"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = local.origin_ids.api_def
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = local.allowed_methods_all
    cached_methods         = local.cached_methods_basic
    compress               = true

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id
  }

  ordered_cache_behavior {
    path_pattern           = "/v1/*"
    target_origin_id       = local.origin_ids.api_api
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = local.allowed_methods_all
    cached_methods         = local.cached_methods_basic
    compress               = true

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.api_acm_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.3_2025"
  }

  tags = var.api_tags
}

resource "aws_s3_bucket_policy" "frontend_oac" {
  bucket = var.s3_bucket_id
  policy = jsonencode({
    Id      = "PolicyForCloudFrontPrivateContent"
    Version = "2008-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontApp"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${var.s3_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.app.arn
          }
        }
      },
      {
        Sid    = "AllowCloudFrontAdmin"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${var.s3_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.admin.arn
          }
        }
      }
    ]
  })
}
