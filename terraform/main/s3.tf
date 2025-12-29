###############################################################
# S3
###############################################################

module "s3" {
  source = "../modules/s3"

  bucket_name        = var.s3_bucket_name
  versioning_enabled = var.s3_versioning_enabled
  sse_algorithm      = var.s3_sse_algorithm
  tags               = local.tags
}
