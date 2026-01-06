###############################################################
# Global Kubernetes ConfigMaps
###############################################################

# Seoul Cluster (Hub)
resource "kubernetes_config_map_v1" "auth_config_seoul" {
  provider = kubernetes.seoul

  metadata {
    name      = "auth-config"
    namespace = local.app_namespace
  }

  data = {
    "AWS_REGION"                  = "ap-northeast-2"
    "DYNAMODB_TABLE_NAME"         = var.dynamodb_table_name
    "JWT_ISSUER"                  = local.jwt_issuer
    "JWT_AUDIENCES"               = local.jwt_audiences
    "OTEL_EXPORTER_OTLP_ENDPOINT" = var.otel_exporter_otlp_endpoint
    "OTEL_EXPORTER_OTLP_PROTOCOL" = "grpc"
    "OTEL_SERVICE_NAME"           = "lionpay-auth"
  }

  depends_on = [module.eks_seoul]
}

resource "kubernetes_config_map_v1" "wallet_config_seoul" {
  provider = kubernetes.seoul

  metadata {
    name      = "wallet-config"
    namespace = local.app_namespace
  }

  data = {
    "AWS_REGION"                  = "ap-northeast-2"
    "WALLETDB_CLUSTER_ENDPOINT"   = "${module.dsql_seoul.identifier}.dsql.ap-northeast-2.on.aws"
    "JWT_ISSUER"                  = local.jwt_issuer
    "JWT_AUDIENCES"               = local.jwt_audiences
    "OTEL_EXPORTER_OTLP_ENDPOINT" = var.otel_exporter_otlp_endpoint
    "OTEL_EXPORTER_OTLP_PROTOCOL" = "grpc"
    "OTEL_SERVICE_NAME"           = "lionpay-wallet"
  }

  depends_on = [module.eks_seoul]
}

# Tokyo Cluster (Spoke)
resource "kubernetes_config_map_v1" "auth_config_tokyo" {
  provider = kubernetes.tokyo

  metadata {
    name      = "auth-config"
    namespace = local.app_namespace
  }

  data = {
    "AWS_REGION"                  = "ap-northeast-1"
    "DYNAMODB_TABLE_NAME"         = var.dynamodb_table_name
    "JWT_ISSUER"                  = local.jwt_issuer
    "JWT_AUDIENCES"               = local.jwt_audiences
    "OTEL_EXPORTER_OTLP_ENDPOINT" = var.otel_exporter_otlp_endpoint
    "OTEL_SERVICE_NAME"           = "lionpay-auth"
  }

  depends_on = [module.eks_tokyo]
}

resource "kubernetes_config_map_v1" "wallet_config_tokyo" {
  provider = kubernetes.tokyo

  metadata {
    name      = "wallet-config"
    namespace = local.app_namespace
  }

  data = {
    "AWS_REGION"                  = "ap-northeast-1"
    "WALLETDB_CLUSTER_ENDPOINT"   = "${module.dsql_tokyo.identifier}.dsql.ap-northeast-1.on.aws"
    "JWT_ISSUER"                  = local.jwt_issuer
    "JWT_AUDIENCES"               = local.jwt_audiences
    "OTEL_EXPORTER_OTLP_ENDPOINT" = var.otel_exporter_otlp_endpoint
    "OTEL_SERVICE_NAME"           = "lionpay-wallet"
  }

  depends_on = [module.eks_tokyo]
}
