resource "aws_dsql_cluster" "this" {
  deletion_protection_enabled = var.deletion_protection_enabled
  force_destroy               = var.force_destroy
  kms_encryption_key          = var.kms_encryption_key
  region                      = var.region
  tags                        = var.tags

  dynamic "multi_region_properties" {
    for_each = var.witness_region == null ? [] : [1]
    content {
      witness_region = var.witness_region
    }
  }
}
