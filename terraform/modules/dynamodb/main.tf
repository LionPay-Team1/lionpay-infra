resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = var.billing_mode
  hash_key     = var.hash_key
  range_key    = var.range_key

  attribute {
    name = var.hash_key
    type = var.hash_key_type
  }

  dynamic "attribute" {
    for_each = var.range_key == null ? [] : [var.range_key]
    content {
      name = attribute.value
      type = var.range_key_type
    }
  }

  stream_enabled   = length(var.replica_regions) > 0 ? true : null
  stream_view_type = length(var.replica_regions) > 0 ? "NEW_AND_OLD_IMAGES" : null

  dynamic "replica" {
    for_each = var.replica_regions
    content {
      region_name = replica.value.region_name
      kms_key_arn = replica.value.kms_key_arn
    }
  }

  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  deletion_protection_enabled = var.deletion_protection

  tags = var.tags
}
