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
# Kubernetes Secrets for DSQL Connection
###############################################################

# Seoul Cluster (Hub)
resource "kubernetes_secret_v1" "wallet_db_config_seoul" {
  provider = kubernetes.seoul

  metadata {
    name      = "wallet-db-secret"
    namespace = "default"
  }

  data = {
    "ConnectionStrings__walletdb" = "Host=${module.dsql_seoul.identifier}.dsql.ap-northeast-2.on.aws;Database=postgres;Username=admin;SslMode=Require;"
    "Dsql__Region"                = "ap-northeast-2"
    "Dsql__TokenRefreshMinutes"   = "12"
  }

  type = "Opaque"

  depends_on = [module.eks_seoul]
}

# Tokyo Cluster (Spoke)
resource "kubernetes_secret_v1" "wallet_db_config_tokyo" {
  provider = kubernetes.tokyo

  metadata {
    name      = "wallet-db-secret"
    namespace = "default"
  }

  data = {
    "ConnectionStrings__walletdb" = "Host=${module.dsql_tokyo.identifier}.dsql.ap-northeast-1.on.aws;Database=postgres;Username=admin;SslMode=Require;"
    "Dsql__Region"                = "ap-northeast-1"
    "Dsql__TokenRefreshMinutes"   = "12"
  }

  type = "Opaque"

  depends_on = [module.eks_tokyo]
}
