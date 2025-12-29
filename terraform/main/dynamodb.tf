###############################################################
# DynamoDB
###############################################################

module "dynamodb" {
  source = "../modules/dynamodb"

  table_name             = var.dynamodb_table_name
  billing_mode           = var.dynamodb_billing_mode
  hash_key               = var.dynamodb_hash_key
  hash_key_type          = var.dynamodb_hash_key_type
  range_key              = var.dynamodb_range_key
  range_key_type         = var.dynamodb_range_key_type
  point_in_time_recovery = var.dynamodb_point_in_time_recovery
  deletion_protection    = var.dynamodb_deletion_protection
  replica_regions        = [{ region_name = "ap-northeast-1" }]
  tags                   = local.tags
}
