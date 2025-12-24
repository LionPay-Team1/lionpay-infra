###############################################################
# DynamoDB Global Table
###############################################################

resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = var.billing_mode
  hash_key     = var.hash_key

  attribute {
    name = var.hash_key
    type = var.hash_key_type
  }

  dynamic "attribute" {
    for_each = var.range_key != null ? [1] : []
    content {
      name = var.range_key
      type = var.range_key_type
    }
  }

  dynamic "range_key" {
    for_each = var.range_key != null ? [1] : []
    content {
      name = var.range_key
    }
  }

  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  deletion_protection_enabled = var.deletion_protection

  dynamic "replica" {
    for_each = var.replica_regions
    content {
      region_name = replica.value.region_name
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [replica]
  }
}
