###############################################################
# ECR Repositories (Seoul & Tokyo)
###############################################################

resource "aws_ecr_repository" "seoul" {
  for_each = toset(var.repositories)

  name                 = each.value
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.kms_key_arn
  }

  force_delete = var.force_delete

  tags = var.tags
}

resource "aws_ecr_repository" "tokyo" {
  for_each = toset(var.repositories)
  provider = aws.tokyo

  name                 = each.value
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.kms_key_arn
  }

  force_delete = var.force_delete

  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "seoul" {
  for_each   = var.lifecycle_policy != null ? toset(var.repositories) : []
  repository = aws_ecr_repository.seoul[each.key].name
  policy     = var.lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "tokyo" {
  for_each   = var.lifecycle_policy != null ? toset(var.repositories) : []
  provider   = aws.tokyo
  repository = aws_ecr_repository.tokyo[each.key].name
  policy     = var.lifecycle_policy
}
