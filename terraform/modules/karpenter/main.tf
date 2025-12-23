locals {
  node_class = {
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name = var.node_class_name
    }
    spec = {
      amiSelectorTerms = [
        {
          alias = var.ami_alias
        }
      ]
      role = var.node_iam_role_name
      subnetSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = var.discovery_tag
          }
        }
      ]
      securityGroupSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = var.discovery_tag
          }
        }
      ]
      tags = {
        "karpenter.sh/discovery" = var.discovery_tag
      }
    }
  }

  node_pool = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = var.node_pool_name
    }
    spec = {
      template = {
        spec = {
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = var.node_class_name
          }
          requirements = [
            {
              key      = "karpenter.k8s.aws/instance-category"
              operator = "In"
              values   = var.instance_categories
            },
            {
              key      = "karpenter.k8s.aws/instance-cpu"
              operator = "In"
              values   = var.instance_cpus
            },
            {
              key      = "karpenter.k8s.aws/instance-hypervisor"
              operator = "In"
              values   = ["nitro"]
            },
            {
              key      = "karpenter.k8s.aws/instance-generation"
              operator = "Gt"
              values   = var.instance_generations
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = var.capacity_types
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = var.architectures
            }
          ]
        }
      }
      limits = {
        cpu = var.node_pool_cpu_limit
      }
      disruption = {
        consolidationPolicy = var.consolidation_policy
        consolidateAfter    = var.consolidate_after
      }
    }
  }
}

module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"
  # version = "~> 20.24"

  cluster_name          = var.cluster_name
  # enable_v1_permissions = true
  namespace             = var.namespace

  node_iam_role_use_name_prefix   = false
  node_iam_role_name              = var.node_iam_role_name
  create_pod_identity_association = true

  tags = var.tags
}

resource "aws_eks_access_entry" "karpenter_nodes" {
  cluster_name  = var.cluster_name
  principal_arn = module.karpenter.node_iam_role_arn
  type          = "EC2_LINUX"

  tags = var.tags
}

resource "helm_release" "karpenter" {
  name                = "karpenter"
  namespace           = var.namespace
  create_namespace    = true
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = var.repository_username
  repository_password = var.repository_password
  chart               = "karpenter"
  version             = var.chart_version
  wait                = false

  values = [
    <<-EOT
    nodeSelector:
      karpenter.sh/controller: "true"
    settings:
      clusterName: ${var.cluster_name}
      clusterEndpoint: ${var.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
      - key: karpenter.sh/controller
        operator: Exists
        effect: NoSchedule
    webhook:
      enabled: false
    EOT
  ]

  lifecycle {
    ignore_changes = [
      repository_password
    ]
  }
}
resource "kubernetes_manifest" "karpenter_node_class" {
  manifest = local.node_class

  depends_on = [
    helm_release.karpenter
  ]
}
resource "kubernetes_manifest" "karpenter_node_pool" {
  manifest = local.node_pool

  depends_on = [
    kubernetes_manifest.karpenter_node_class
  ]
}