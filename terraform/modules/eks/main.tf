###############################################################
# EKS Cluster with Managed Node Group + Karpenter
###############################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  endpoint_public_access = var.cluster_endpoint_public_access

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  enable_cluster_creator_admin_permissions = true

  # Disable Auto Mode - using Managed Node Group + Karpenter instead
  compute_config = {
    enabled = false
  }

  # Managed Node Group for system workloads (Karpenter controller, CoreDNS, etc.)
  eks_managed_node_groups = {
    system = {
      name           = "system"
      instance_types = var.system_node_instance_types
      ami_type       = "AL2023_ARM_64_STANDARD"

      min_size     = var.system_node_min_size
      max_size     = var.system_node_max_size
      desired_size = var.system_node_desired_size

      labels = {
        "node-type" = "system"
      }

      taints = {
        critical_addons_only = {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  # Access entry for Karpenter nodes (EC2 type doesn't need policy_associations)
  access_entries = {
    karpenter_nodes = {
      principal_arn = aws_iam_role.karpenter_node_role.arn
      type          = "EC2_LINUX"
    }
  }

  # Node security group tags for Karpenter discovery
  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  # EKS Addons
  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      # Specify the VPC CNI addon should be deployed before compute to ensure
      # the addon is configured before data plane compute resources are created
      # See README for further details
      before_compute = true
      most_recent    = true # To ensure access to the latest settings provided
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  tags = var.tags
}

###############################################################
# IAM Role for Karpenter Nodes
###############################################################

resource "aws_iam_role" "karpenter_node_role" {
  name = "${var.cluster_name}-karpenter-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = var.tags
}

# Attach required policies for Karpenter worker nodes
resource "aws_iam_role_policy_attachment" "karpenter_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.karpenter_node_role.name
}

resource "aws_iam_role_policy_attachment" "karpenter_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.karpenter_node_role.name
}

resource "aws_iam_role_policy_attachment" "karpenter_ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.karpenter_node_role.name
}

resource "aws_iam_role_policy_attachment" "karpenter_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.karpenter_node_role.name
}

resource "aws_iam_instance_profile" "karpenter" {
  name = "${var.cluster_name}-karpenter-node-profile"
  role = aws_iam_role.karpenter_node_role.name
}
