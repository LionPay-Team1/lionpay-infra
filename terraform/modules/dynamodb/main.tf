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

  # GSI용 추가 속성 정의
  dynamic "attribute" {
    for_each = var.global_secondary_indexes
    content {
      name = attribute.value.hash_key
      type = attribute.value.hash_key_type
    }
  }

  dynamic "attribute" {
    for_each = [for gsi in var.global_secondary_indexes : gsi if gsi.range_key != null]
    content {
      name = attribute.value.range_key
      type = attribute.value.range_key_type
    }
  }

  # Global Secondary Indexes
  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = global_secondary_index.value.range_key
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = global_secondary_index.value.projection_type == "INCLUDE" ? global_secondary_index.value.non_key_attributes : null
    }
  }

  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  # Server-Side Encryption
  server_side_encryption {
    enabled = var.server_side_encryption
  }

  deletion_protection_enabled = var.deletion_protection

  tags = var.tags
}
