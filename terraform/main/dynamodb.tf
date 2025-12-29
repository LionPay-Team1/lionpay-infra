###############################################################
# DynamoDB
###############################################################

module "dynamodb" {
  source = "../modules/dynamodb"

  table_name             = var.dynamodb_table_name
  billing_mode           = "PAY_PER_REQUEST"
  hash_key               = var.dynamodb_hash_key
  hash_key_type          = "S"
  range_key              = var.dynamodb_range_key
  range_key_type         = "S"
  point_in_time_recovery = false
  deletion_protection    = false
  replica_regions        = [{ region_name = "ap-northeast-1" }]
  tags                   = local.tags
}
