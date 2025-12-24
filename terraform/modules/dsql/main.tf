resource "aws_dsql_cluster" "this" {
  deletion_protection_enabled = var.deletion_protection_enabled
  force_destroy               = var.force_destroy
  kms_encryption_key          = var.kms_encryption_key
  tags                        = var.tags

  multi_region_properties {
    witness_region = var.witness_region
    # clusters       = var.linked_cluster_arns
  }
}
