include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path   = "${dirname(find_in_parent_folders())}/environments/dev/env.hcl"
  expose = true
}

terraform {
  source = "${dirname(find_in_parent_folders())}/_envcommon/dynamodb"
}

inputs = {
  table_name             = include.env.locals.dynamodb_table_name
  hash_key               = include.env.locals.dynamodb_hash_key
  billing_mode           = "PAY_PER_REQUEST"
  point_in_time_recovery = false
  deletion_protection    = false

  replica_regions = [
    { region_name = "ap-northeast-1" }
  ]

  tags = include.env.locals.tags
}
