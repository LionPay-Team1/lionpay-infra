include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${dirname(find_in_parent_folders())}/shared/ecr"
}

inputs = {
  repositories = [
    "lionpay-auth",
    "lionpay-wallet"
  ]

  image_tag_mutability = "IMMUTABLE"
  scan_on_push         = true
  force_delete         = false
  encryption_type      = "AES256"

  tags = {
    Project = "lionpay"
  }
}
