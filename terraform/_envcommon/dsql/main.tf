###############################################################
# DSQL Multi-Region Clusters (Seoul & Tokyo)
###############################################################

resource "aws_dsql_cluster" "seoul" {
  deletion_protection_enabled = var.deletion_protection_enabled

  tags = merge(var.tags, {
    Name   = "${var.project_name}-${var.env}-dsql-seoul"
    Region = var.region_seoul
  })
}

resource "aws_dsql_cluster" "tokyo" {
  provider                    = aws.tokyo
  deletion_protection_enabled = var.deletion_protection_enabled

  tags = merge(var.tags, {
    Name   = "${var.project_name}-${var.env}-dsql-tokyo"
    Region = var.region_tokyo
  })
}

###############################################################
# DSQL VPC Interface Endpoints
###############################################################

resource "aws_security_group" "dsql_endpoint_seoul" {
  name        = "${var.project_name}-${var.env}-dsql-endpoint-seoul"
  description = "Security group for DSQL VPC Endpoint in Seoul"
  vpc_id      = var.seoul_vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.seoul_vpc_cidr_block]
  }

  tags = var.tags
}

resource "aws_security_group" "dsql_endpoint_tokyo" {
  provider    = aws.tokyo
  name        = "${var.project_name}-${var.env}-dsql-endpoint-tokyo"
  description = "Security group for DSQL VPC Endpoint in Tokyo"
  vpc_id      = var.tokyo_vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.tokyo_vpc_cidr_block]
  }

  tags = var.tags
}

resource "aws_vpc_endpoint" "dsql_seoul" {
  vpc_id              = var.seoul_vpc_id
  service_name        = aws_dsql_cluster.seoul.endpoint[0].vpc_endpoint_service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = var.seoul_private_subnets
  security_group_ids = [aws_security_group.dsql_endpoint_seoul.id]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.env}-dsql-vpce-seoul"
  })
}

resource "aws_vpc_endpoint" "dsql_tokyo" {
  provider            = aws.tokyo
  vpc_id              = var.tokyo_vpc_id
  service_name        = aws_dsql_cluster.tokyo.endpoint[0].vpc_endpoint_service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = var.tokyo_private_subnets
  security_group_ids = [aws_security_group.dsql_endpoint_tokyo.id]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.env}-dsql-vpce-tokyo"
  })
}

###############################################################
# DSQL IRSA (IAM Roles for Service Accounts)
###############################################################

resource "aws_iam_policy" "dsql_connect_seoul" {
  name        = "${var.project_name}-${var.env}-dsql-connect-seoul"
  description = "Allow DB connection to Seoul DSQL Cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "dsql:DbConnect"
        Effect   = "Allow"
        Resource = aws_dsql_cluster.seoul.arn
      },
      {
        Action   = "dsql:DbConnect"
        Effect   = "Allow"
        Resource = "${aws_dsql_cluster.seoul.arn}/*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "dsql_connect_tokyo" {
  provider    = aws.tokyo
  name        = "${var.project_name}-${var.env}-dsql-connect-tokyo"
  description = "Allow DB connection to Tokyo DSQL Cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "dsql:DbConnect"
        Effect   = "Allow"
        Resource = aws_dsql_cluster.tokyo.arn
      },
      {
        Action   = "dsql:DbConnect"
        Effect   = "Allow"
        Resource = "${aws_dsql_cluster.tokyo.arn}/*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role" "service_account_seoul" {
  name = "${var.project_name}-${var.env}-sa-seoul"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.seoul_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.seoul_oidc_provider_arn, "https://", "")}:sub" = "system:serviceaccount:default:dsql-app"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "sa_seoul_dsql" {
  role       = aws_iam_role.service_account_seoul.name
  policy_arn = aws_iam_policy.dsql_connect_seoul.arn
}

resource "aws_iam_role" "service_account_tokyo" {
  name = "${var.project_name}-${var.env}-sa-tokyo"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.tokyo_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.tokyo_oidc_provider_arn, "https://", "")}:sub" = "system:serviceaccount:default:dsql-app"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "sa_tokyo_dsql" {
  role       = aws_iam_role.service_account_tokyo.name
  policy_arn = aws_iam_policy.dsql_connect_tokyo.arn
}
