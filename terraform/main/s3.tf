###############################################################
# S3
###############################################################

module "frontend_s3" {
  source = "../modules/s3"

  bucket_name        = "lionpay-${var.env}-frontend"
  versioning_enabled = true
  sse_algorithm      = "AES256"
  tags               = local.tags
}
