###############################################################
# ECR Repository (Seoul) - Replication Source
###############################################################

data "aws_caller_identity" "current" {}

module "ecr_central" {
  for_each = toset(var.repositories)
  source   = "../modules/ecr"

  name                 = each.value
  image_tag_mutability = "IMMUTABLE"
  scan_on_push         = true
  force_delete         = false
  encryption_type      = "AES256"
  kms_key_arn          = null
  lifecycle_policy     = null
  tags                 = local.tags
}

###############################################################
# ECR Replication Configuration (Seoul -> Tokyo)
###############################################################

resource "aws_ecr_replication_configuration" "replication" {
  replication_configuration {
    rule {
      destination {
        region      = "ap-northeast-1"
        registry_id = data.aws_caller_identity.current.account_id
      }
    }
  }
}

###############################################################
# Local Variables
###############################################################

locals {
  tags = merge(var.tags, {
    Project   = var.project_name
    ManagedBy = "terraform"
  })
}
