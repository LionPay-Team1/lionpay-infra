###############################################################
# Karpenter Configuration - StorageClass only
# Note: EC2NodeClass, NodePools, IngressClass are applied after
# EKS Blueprints Addons install Karpenter and ALB Controller
###############################################################

locals {
  storageclass_yamls = [
    "ebs-storageclass.yaml"
  ]
}

# Apply default storage class
resource "kubernetes_manifest" "storageclass" {
  for_each = toset(local.storageclass_yamls)

  manifest = yamldecode(file("${path.module}/config/${each.value}"))
}
