include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path   = "${dirname(find_in_parent_folders())}/environments/prod/env.hcl"
  expose = true
}

terraform {
  source = "${dirname(find_in_parent_folders())}/_envcommon/s3"
}

inputs = {
  bucket_name        = include.env.locals.s3_bucket_name
  versioning_enabled = true
  sse_algorithm      = "AES256"

  tags = include.env.locals.tags
}
