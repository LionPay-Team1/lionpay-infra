###############################################################
# DSQL Multi-Region Clusters
###############################################################

# Seoul Cluster
module "dsql_seoul" {
  source = "../modules/dsql"
  providers = {
    aws = aws
  }

  deletion_protection_enabled = false
  witness_region              = "ap-northeast-3"

  tags = merge(local.tags, {
    Name   = "${local.name_prefix}-dsql-seoul"
    Region = "ap-northeast-2"
  })
}

# Tokyo Cluster
module "dsql_tokyo" {
  source = "../modules/dsql"
  providers = {
    aws = aws.tokyo
  }

  deletion_protection_enabled = false
  witness_region              = "ap-northeast-3"

  tags = merge(local.tags, {
    Name   = "${local.name_prefix}-dsql-tokyo"
    Region = "ap-northeast-1"
  })
}

# Peering Seoul to Tokyo
# resource "null_resource" "peering_dsql_seoul_to_tokyo" {
#   provisioner "local-exec" {
#     command = "aws dsql update-cluster --region ap-northeast-2 --identifier ${module.dsql_seoul.identifier} --multi-region-properties '{\"witnessRegion\": \"${"ap-northeast-3"}\", \"clusters\": [\"${module.dsql_tokyo.arn}\"]}'"
#   }

#   depends_on = [module.dsql_seoul, module.dsql_tokyo]
# }

# resource "null_resource" "peering_dsql_tokyo_to_seoul" {
#   provisioner "local-exec" {
#     command = "aws dsql update-cluster --region ap-northeast-1 --identifier ${module.dsql_tokyo.identifier} --multi-region-properties '{\"witnessRegion\": \"${"ap-northeast-3"}\", \"clusters\": [\"${module.dsql_seoul.arn}\"]}'"
#   }

#   depends_on = [module.dsql_seoul, module.dsql_tokyo]
# }


###############################################################
# DSQL VPC Interface Endpoints
###############################################################

# Security Group for DSQL Endpoints (Allow 5432 from VPC)
resource "aws_security_group" "dsql_endpoint_seoul" {
  name        = "${local.name_prefix}-dsql-endpoint-seoul"
  description = "Security group for DSQL VPC Endpoint in Seoul"
  vpc_id      = module.vpc_seoul.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc_seoul.vpc_cidr_block]
  }

  tags = local.tags
}

resource "aws_security_group" "dsql_endpoint_tokyo" {
  provider    = aws.tokyo
  name        = "${local.name_prefix}-dsql-endpoint-tokyo"
  description = "Security group for DSQL VPC Endpoint in Tokyo"
  vpc_id      = module.vpc_tokyo.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc_tokyo.vpc_cidr_block]
  }

  tags = local.tags
}

# VPC Endpoint - Seoul (Connects to Seoul DSQL)
resource "aws_vpc_endpoint" "dsql_seoul" {
  vpc_id              = module.vpc_seoul.vpc_id
  service_name        = module.dsql_seoul.vpc_endpoint_service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = module.vpc_seoul.private_subnets
  security_group_ids = [aws_security_group.dsql_endpoint_seoul.id]

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-dsql-vpce-seoul"
  })
}

# VPC Endpoint - Tokyo (Connects to Tokyo DSQL)
resource "aws_vpc_endpoint" "dsql_tokyo" {
  provider            = aws.tokyo
  vpc_id              = module.vpc_tokyo.vpc_id
  service_name        = module.dsql_tokyo.vpc_endpoint_service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = module.vpc_tokyo.private_subnets
  security_group_ids = [aws_security_group.dsql_endpoint_tokyo.id]

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-dsql-vpce-tokyo"
  })
}

###############################################################
# DSQL IRSA (IAM Roles for Service Accounts)
###############################################################

# Policy for Seoul DSQL Connection
resource "aws_iam_policy" "dsql_connect_seoul" {
  name        = "${local.name_prefix}-dsql-connect-seoul"
  description = "Allow DB connection to Seoul DSQL Cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "dsql:DbConnect"
        Effect   = "Allow"
        Resource = module.dsql_seoul.arn
      },
      {
        Action   = "dsql:DbConnect"
        Effect   = "Allow"
        Resource = "${module.dsql_seoul.arn}/*"
      }
    ]
  })

  tags = local.tags
}

# Policy for Tokyo DSQL Connection
resource "aws_iam_policy" "dsql_connect_tokyo" {
  provider    = aws.tokyo
  name        = "${local.name_prefix}-dsql-connect-tokyo"
  description = "Allow DB connection to Tokyo DSQL Cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "dsql:DbConnect"
        Effect   = "Allow"
        Resource = module.dsql_tokyo.arn
      },
      {
        Action   = "dsql:DbConnect"
        Effect   = "Allow"
        Resource = "${module.dsql_tokyo.arn}/*"
      }
    ]
  })

  tags = local.tags
}

# Role for Seoul Cluster
resource "aws_iam_role" "service_account_seoul" {
  name = "${local.name_prefix}-sa-seoul"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks_seoul.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(module.eks_seoul.oidc_provider_arn, "https://", "")}:sub" = "system:serviceaccount:default:dsql-app"
          }
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "sa_seoul_dsql" {
  role       = aws_iam_role.service_account_seoul.name
  policy_arn = aws_iam_policy.dsql_connect_seoul.arn
}

# Role for Tokyo Cluster
resource "aws_iam_role" "service_account_tokyo" {
  name = "${local.name_prefix}-sa-tokyo"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks_tokyo.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(module.eks_tokyo.oidc_provider_arn, "https://", "")}:sub" = "system:serviceaccount:default:dsql-app"
          }
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "sa_tokyo_dsql" {
  role       = aws_iam_role.service_account_tokyo.name
  policy_arn = aws_iam_policy.dsql_connect_tokyo.arn
}
