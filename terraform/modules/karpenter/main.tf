locals {
  namespace = "karpenter"
}

################################################################################
# Controller & Node IAM roles, SQS Queue, Eventbridge Rules
################################################################################

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 21.0"

  cluster_name = var.cluster_name

  # Name needs to match role name passed to the EC2NodeClass
  create_node_iam_role            = false
  node_iam_role_use_name_prefix   = false
  node_iam_role_name              = var.node_iam_role_name
  node_iam_role_arn               = var.node_iam_role_arn
  create_pod_identity_association = true
  create_access_entry             = false

  # Pod Identity Association namespace must match Helm release namespace
  namespace = local.namespace

  tags = var.tags
}

################################################################################
# Helm charts
################################################################################

resource "helm_release" "karpenter" {
  name             = "karpenter"
  namespace        = local.namespace
  create_namespace = true
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = var.karpenter_version
  wait             = false

  values = [
    templatefile("${path.module}/values-karpenter.tftpl", {
      cluster_name     = var.cluster_name
      cluster_endpoint = var.cluster_endpoint
      queue_name       = module.karpenter.queue_name
      service_account  = module.karpenter.service_account
    })
  ]
}

################################################################################
# Metrics Server
################################################################################

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.metrics_server_version
  wait       = true
  atomic     = true

  values = [file("${path.module}/values-metrics-server.tftpl")]
}
