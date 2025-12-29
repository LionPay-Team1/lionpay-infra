locals {
  tags = merge(var.tags, {
    Project = "lionpay"
  })
}

module "ecr_seoul" {
  for_each = toset(var.repositories)
  source   = "../modules/ecr"

  name                 = each.value
  image_tag_mutability = var.image_tag_mutability
  scan_on_push         = var.scan_on_push
  force_delete         = var.force_delete
  encryption_type      = var.encryption_type
  kms_key_arn          = var.kms_key_arn
  lifecycle_policy     = var.lifecycle_policy
  tags                 = local.tags
}

module "ecr_tokyo" {
  for_each = toset(var.repositories)
  source   = "../modules/ecr"
  providers = {
    aws = aws.tokyo
  }

  name                 = each.value
  image_tag_mutability = var.image_tag_mutability
  scan_on_push         = var.scan_on_push
  force_delete         = var.force_delete
  encryption_type      = var.encryption_type
  kms_key_arn          = var.kms_key_arn
  lifecycle_policy     = var.lifecycle_policy
  tags                 = local.tags
}
