###############################################################
# IRSA (IAM Roles for Service Accounts) - Unified for all services
###############################################################

# Policy for Seoul DSQL Connection
resource "aws_iam_policy" "dsql_connect_seoul" {
  name        = "${local.name_prefix}-dsql-connect-seoul"
  description = "Allow DB connection to Seoul DSQL Cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dsql:DbConnect",
          "dsql:DbConnectAdmin"
        ]
        Effect   = "Allow"
        Resource = module.dsql_seoul.arn
      },
      {
        Action = [
          "dsql:DbConnect",
          "dsql:DbConnectAdmin"
        ]
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
        Action = [
          "dsql:DbConnect",
          "dsql:DbConnectAdmin"
        ]
        Effect   = "Allow"
        Resource = module.dsql_tokyo.arn
      },
      {
        Action = [
          "dsql:DbConnect",
          "dsql:DbConnectAdmin"
        ]
        Effect   = "Allow"
        Resource = "${module.dsql_tokyo.arn}/*"
      }
    ]
  })

  tags = local.tags
}

# Unified Role for Seoul Cluster (DSQL + DynamoDB)
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
            "${module.eks_seoul.oidc_provider}:sub" = "system:serviceaccount:${local.app_namespace}:lionpay-app"
            "${module.eks_seoul.oidc_provider}:aud" = "sts.amazonaws.com"
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

resource "aws_iam_role_policy_attachment" "sa_seoul_dynamodb" {
  role       = aws_iam_role.service_account_seoul.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# Unified Role for Tokyo Cluster (DSQL + DynamoDB)
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
            "${module.eks_tokyo.oidc_provider}:sub" = "system:serviceaccount:${local.app_namespace}:lionpay-app"
            "${module.eks_tokyo.oidc_provider}:aud" = "sts.amazonaws.com"
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

resource "aws_iam_role_policy_attachment" "sa_tokyo_dynamodb" {
  role       = aws_iam_role.service_account_tokyo.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

###############################################################
# Kubernetes ServiceAccount (Unified for all services)
###############################################################

resource "kubernetes_service_account_v1" "lionpay_app_seoul" {
  provider = kubernetes.seoul

  metadata {
    name      = "lionpay-app"
    namespace = local.app_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.service_account_seoul.arn
    }
  }

  depends_on = [
    module.eks_seoul,
    kubernetes_namespace_v1.lionpay_seoul
  ]
}

resource "kubernetes_service_account_v1" "lionpay_app_tokyo" {
  provider = kubernetes.tokyo

  metadata {
    name      = "lionpay-app"
    namespace = local.app_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.service_account_tokyo.arn
    }
  }

  depends_on = [
    module.eks_tokyo,
    kubernetes_namespace_v1.lionpay_tokyo
  ]
}
