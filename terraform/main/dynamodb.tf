###############################################################
# DynamoDB
###############################################################

module "dynamodb" {
  source = "../modules/dynamodb"

  table_name             = var.dynamodb_table_name
  billing_mode           = "PAY_PER_REQUEST"
  hash_key               = local.dynamodb_hash_key
  hash_key_type          = "S"
  range_key              = local.dynamodb_range_key
  range_key_type         = "S"
  point_in_time_recovery = false
  deletion_protection    = false
  replica_regions        = [{ region_name = "ap-northeast-1" }]

  # CloudFormation 로컬 개발 환경과 동일하게 GSI 추가
  global_secondary_indexes = [
    {
      name            = "byRefreshToken"
      hash_key        = "token"
      hash_key_type   = "S"
      projection_type = "ALL"
    }
  ]

  # Server-Side Encryption 활성화
  server_side_encryption = true

  tags = local.tags
}
