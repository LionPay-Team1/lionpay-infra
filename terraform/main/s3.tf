###############################################################
# S3
###############################################################

module "s3" {
  source = "../modules/s3"

  bucket_name        = var.s3_bucket_name
  versioning_enabled = true
  sse_algorithm      = "AES256"
  tags               = local.tags
}
