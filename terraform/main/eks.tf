###############################################################
# EKS Cluster Auth Data Sources
###############################################################

# EKS Cluster Auth for Seoul (Hub)
data "aws_eks_cluster_auth" "seoul" {
  name       = module.eks_seoul.cluster_name
  depends_on = [module.eks_seoul]
}

# EKS Cluster Auth for Tokyo (Spoke)
data "aws_eks_cluster_auth" "tokyo" {
  provider   = aws.tokyo
  name       = module.eks_tokyo.cluster_name
  depends_on = [module.eks_tokyo]
}

###############################################################
# EKS Clusters - Seoul (Hub) & Tokyo (Spoke)
###############################################################

# Seoul Cluster - ArgoCD Hub & Service
module "eks_seoul" {
  source = "../modules/eks"
  providers = {
    aws  = aws.seoul
    helm = helm.seoul
  }

  cluster_name         = local.seoul_cluster_name
  cluster_version      = var.kubernetes_version
  vpc_id               = module.vpc_seoul.vpc_id
  private_subnets      = module.vpc_seoul.private_subnets
  environment          = var.env
  admin_principal_arns = var.admin_principal_arns

  # Managed Node Group settings
  mng_instance_types = var.mng_instance_types
  mng_min_size       = var.mng_min_size
  mng_max_size       = var.mng_max_size
  mng_desired_size   = var.mng_desired_size

  # Karpenter Helm chart credentials


  tags = local.tags

  depends_on = [module.vpc_seoul]
}

# Tokyo Cluster - Service Spoke
module "eks_tokyo" {
  source = "../modules/eks"
  providers = {
    aws  = aws.tokyo
    helm = helm.tokyo
  }

  cluster_name         = local.tokyo_cluster_name
  cluster_version      = var.kubernetes_version
  vpc_id               = module.vpc_tokyo.vpc_id
  private_subnets      = module.vpc_tokyo.private_subnets
  environment          = var.env
  admin_principal_arns = var.admin_principal_arns

  # Managed Node Group settings
  mng_instance_types = var.mng_instance_types
  mng_min_size       = var.mng_min_size
  mng_max_size       = var.mng_max_size
  mng_desired_size   = var.mng_desired_size


  # Karpenter Helm chart credentials


  tags = local.tags

  depends_on = [module.vpc_tokyo]
}

###############################################################
# IAM Role for ArgoCD Capability
###############################################################

resource "aws_iam_role" "argocd_capability" {
  name = "${local.name_prefix}-argocd-capability"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "capabilities.eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "capabilities.eks.amazonaws.com"
        }
        Action = "sts:TagSession"
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "argocd_capability_secrets" {
  role       = aws_iam_role.argocd_capability.name
  policy_arn = "arn:aws:iam::aws:policy/AWSSecretsManagerClientReadOnlyAccess"
}

# Required policies for ArgoCD capability
resource "aws_iam_role_policy" "argocd_capability" {
  name = "${local.name_prefix}-argocd-capability-policy"
  role = aws_iam_role.argocd_capability.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sso:DescribeInstance",
          "sso:CreateApplication",
          "sso:DeleteApplication",
          "sso:PutApplicationGrant",
          "sso:PutApplicationAuthenticationMethod",
          "sso:PutApplicationAccessScope",
          "sso:ListApplicationAccessScopes",
          "sso:GetApplicationGrant"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sso-oauth:CreateTokenWithIAM"
        ]
        Resource = "*"
      }
    ]
  })
}

###############################################################
# EKS Capability - ArgoCD (Seoul Hub only)
###############################################################

resource "aws_eks_capability" "argocd_seoul" {
  cluster_name              = module.eks_seoul.cluster_name
  capability_name           = "argocd"
  type                      = "ARGOCD"
  role_arn                  = aws_iam_role.argocd_capability.arn
  delete_propagation_policy = "RETAIN"

  configuration {
    argo_cd {
      namespace = "argocd"
      rbac_role_mapping {
        identity {
          type = "SSO_GROUP"
          id   = var.argocd_admin_group_id
        }
        role = "ADMIN"
      }
      aws_idc {
        idc_instance_arn = var.idc_instance_arn
        idc_region       = var.idc_region
      }
    }
  }

  tags = local.tags

  depends_on = [module.eks_seoul]
}

###############################################################
# Karpenter - Seoul (Hub) & Tokyo (Spoke)
###############################################################

module "karpenter_seoul" {
  source = "../modules/karpenter"
  providers = {
    aws  = aws.seoul
    helm = helm.seoul
  }

  cluster_name              = module.eks_seoul.cluster_name
  cluster_endpoint          = module.eks_seoul.cluster_endpoint
  cluster_oidc_provider_arn = module.eks_seoul.oidc_provider_arn
  node_iam_role_name        = module.eks_seoul.karpenter_node_iam_role_name
  node_iam_role_arn         = module.eks_seoul.karpenter_node_iam_role_arn

  tags = local.tags

  depends_on = [module.eks_seoul]
}

module "karpenter_tokyo" {
  source = "../modules/karpenter"
  providers = {
    aws  = aws.tokyo
    helm = helm.tokyo
  }

  cluster_name              = module.eks_tokyo.cluster_name
  cluster_endpoint          = module.eks_tokyo.cluster_endpoint
  cluster_oidc_provider_arn = module.eks_tokyo.oidc_provider_arn
  node_iam_role_name        = module.eks_tokyo.karpenter_node_iam_role_name
  node_iam_role_arn         = module.eks_tokyo.karpenter_node_iam_role_arn

  tags = local.tags

  depends_on = [module.eks_tokyo]
}

###############################################################
# Karpenter Config Automation
###############################################################

resource "local_file" "karpenter_seoul_manifest" {
  content = templatefile("${path.module}/config/${var.env}-karpenter.yaml", {
    cluster_name          = module.eks_seoul.cluster_name
    environment           = var.env
    instance_profile_name = module.eks_seoul.karpenter_instance_profile_name
  })
  filename = "${path.module}/.terraform/karpenter_seoul.yaml"
}

resource "null_resource" "karpenter_seoul_apply" {
  triggers = {
    manifest_sha1 = sha1(local_file.karpenter_seoul_manifest.content)
    cluster_name  = module.eks_seoul.cluster_name
    region        = "ap-northeast-2"
    manifest_file = local_file.karpenter_seoul_manifest.filename
    kubeconfig    = "${path.module}/.terraform/kubeconfig_seoul"
  }

  # 1. Update Kubeconfig
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks_seoul.cluster_name} --region ap-northeast-2"
    environment = {
      KUBECONFIG = "${path.module}/.terraform/kubeconfig_seoul"
    }
  }

  # 2. Apply Manifest
  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.karpenter_seoul_manifest.filename}"
    environment = {
      KUBECONFIG = "${path.module}/.terraform/kubeconfig_seoul"
    }
  }

  # 3. Delete Manifest on Destroy
  provisioner "local-exec" {
    when       = destroy
    command    = <<-EOT
      CLUSTER_NAME="${try(self.triggers.cluster_name, "")}"
      REGION="${try(self.triggers.region, "ap-northeast-2")}"
      MANIFEST_FILE="${try(self.triggers.manifest_file, "")}"
      if [ -n "$CLUSTER_NAME" ] && [ -n "$MANIFEST_FILE" ]; then
        aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION" || true
        kubectl delete -f "$MANIFEST_FILE" --ignore-not-found || true
      fi
    EOT
    on_failure = continue
  }

  depends_on = [module.karpenter_seoul]
}

resource "local_file" "karpenter_tokyo_manifest" {
  content = templatefile("${path.module}/config/${var.env}-karpenter.yaml", {
    cluster_name          = module.eks_tokyo.cluster_name
    environment           = var.env
    instance_profile_name = module.eks_tokyo.karpenter_instance_profile_name
  })
  filename = "${path.module}/.terraform/karpenter_tokyo.yaml"
}

resource "null_resource" "karpenter_tokyo_apply" {
  triggers = {
    manifest_sha1 = sha1(local_file.karpenter_tokyo_manifest.content)
    cluster_name  = module.eks_tokyo.cluster_name
    region        = "ap-northeast-1"
    manifest_file = local_file.karpenter_tokyo_manifest.filename
    kubeconfig    = "${path.module}/.terraform/kubeconfig_tokyo"
  }

  # 1. Update Kubeconfig
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks_tokyo.cluster_name} --region ap-northeast-1"
    environment = {
      KUBECONFIG = "${path.module}/.terraform/kubeconfig_tokyo"
    }
  }

  # 2. Apply Manifest
  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.karpenter_tokyo_manifest.filename}"
    environment = {
      KUBECONFIG = "${path.module}/.terraform/kubeconfig_tokyo"
    }
  }

  # 3. Delete Manifest on Destroy
  provisioner "local-exec" {
    when       = destroy
    command    = <<-EOT
      CLUSTER_NAME="${try(self.triggers.cluster_name, "")}"
      REGION="${try(self.triggers.region, "ap-northeast-1")}"
      MANIFEST_FILE="${try(self.triggers.manifest_file, "")}"
      if [ -n "$CLUSTER_NAME" ] && [ -n "$MANIFEST_FILE" ]; then
        aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION" || true
        kubectl delete -f "$MANIFEST_FILE" --ignore-not-found || true
      fi
    EOT
    on_failure = continue
  }

  depends_on = [module.karpenter_tokyo]
}

###############################################################
# Alloy (Grafana Cloud Monitoring) - Seoul & Tokyo
###############################################################

module "monitoring_seoul" {
  source = "../modules/grafana-k8s-monitoring"

  providers = {
    helm       = helm.seoul
    kubernetes = kubernetes.seoul
  }

  cluster_name = local.seoul_cluster_name

  destinations_prometheus_url      = var.destinations_prometheus_url
  destinations_prometheus_username = var.destinations_prometheus_username
  destinations_prometheus_password = var.destinations_prometheus_password

  destinations_loki_url      = var.destinations_loki_url
  destinations_loki_username = var.destinations_loki_username
  destinations_loki_password = var.destinations_loki_password

  destinations_otlp_url      = var.destinations_otlp_url
  destinations_otlp_username = var.destinations_otlp_username
  destinations_otlp_password = var.destinations_otlp_password

  fleetmanagement_url      = var.fleetmanagement_url
  fleetmanagement_username = var.fleetmanagement_username
  fleetmanagement_password = var.fleetmanagement_password

  depends_on = [module.eks_seoul]
}

module "monitoring_tokyo" {
  source = "../modules/grafana-k8s-monitoring"

  providers = {
    helm       = helm.tokyo
    kubernetes = kubernetes.tokyo
  }

  cluster_name = local.tokyo_cluster_name

  destinations_prometheus_url      = var.destinations_prometheus_url
  destinations_prometheus_username = var.destinations_prometheus_username
  destinations_prometheus_password = var.destinations_prometheus_password

  destinations_loki_url      = var.destinations_loki_url
  destinations_loki_username = var.destinations_loki_username
  destinations_loki_password = var.destinations_loki_password

  destinations_otlp_url      = var.destinations_otlp_url
  destinations_otlp_username = var.destinations_otlp_username
  destinations_otlp_password = var.destinations_otlp_password

  fleetmanagement_url      = var.fleetmanagement_url
  fleetmanagement_username = var.fleetmanagement_username
  fleetmanagement_password = var.fleetmanagement_password

  depends_on = [module.eks_tokyo]
}

###############################################################
# AWS Load Balancer Controller - Seoul (Hub) & Tokyo (Spoke)
###############################################################

resource "helm_release" "aws_load_balancer_controller_seoul" {
  provider   = helm.seoul
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.0"

  set {
    name  = "clusterName"
    value = module.eks_seoul.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.eks_seoul.load_balancer_controller_iam_role_arn
  }

  set {
    name  = "vpcId"
    value = module.vpc_seoul.vpc_id
  }

  set {
    name  = "awsRegion"
    value = "ap-northeast-2"
  }

  depends_on = [module.eks_seoul]
}

resource "helm_release" "aws_load_balancer_controller_tokyo" {
  provider   = helm.tokyo
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.1"

  set {
    name  = "clusterName"
    value = module.eks_tokyo.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.eks_tokyo.load_balancer_controller_iam_role_arn
  }

  set {
    name  = "vpcId"
    value = module.vpc_tokyo.vpc_id
  }

  set {
    name  = "awsRegion"
    value = "ap-northeast-1"
  }

  depends_on = [module.eks_tokyo]
}

###############################################################
# Ingress Cleanup - Delete Ingresses before LB Controller is removed
###############################################################

resource "null_resource" "ingress_cleanup_seoul" {
  triggers = {
    cluster_name = module.eks_seoul.cluster_name
    region       = "ap-northeast-2"
  }

  # Destroy 시 Ingress 삭제 (ALB Controller가 삭제되기 전에 실행)
  provisioner "local-exec" {
    when       = destroy
    command    = <<-EOT
      CLUSTER_NAME="${try(self.triggers.cluster_name, "")}"
      REGION="${try(self.triggers.region, "ap-northeast-2")}"
      
      if [ -n "$CLUSTER_NAME" ]; then
        echo "Updating kubeconfig for $CLUSTER_NAME..."
        aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION" || true
        
        echo "Deleting all Ingress resources..."
        kubectl delete ingress --all -A --ignore-not-found || true
        
        echo "Waiting for ALB cleanup (60 seconds)..."
        sleep 60
        
        echo "Cleaning up orphaned ALB Security Groups..."
        for sg in $(aws ec2 describe-security-groups --region "$REGION" \
          --filters "Name=tag-key,Values=elbv2.k8s.aws/cluster" \
          --query "SecurityGroups[].GroupId" --output text 2>/dev/null); do
          echo "Deleting Security Group: $sg"
          aws ec2 delete-security-group --group-id "$sg" --region "$REGION" 2>/dev/null || true
        done
      fi
    EOT
    on_failure = continue
  }

  depends_on = [helm_release.aws_load_balancer_controller_seoul]
}

resource "null_resource" "ingress_cleanup_tokyo" {
  triggers = {
    cluster_name = module.eks_tokyo.cluster_name
    region       = "ap-northeast-1"
  }

  # Destroy 시 Ingress 삭제 (ALB Controller가 삭제되기 전에 실행)
  provisioner "local-exec" {
    when       = destroy
    command    = <<-EOT
      CLUSTER_NAME="${try(self.triggers.cluster_name, "")}"
      REGION="${try(self.triggers.region, "ap-northeast-1")}"
      
      if [ -n "$CLUSTER_NAME" ]; then
        echo "Updating kubeconfig for $CLUSTER_NAME..."
        aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION" || true
        
        echo "Deleting all Ingress resources..."
        kubectl delete ingress --all -A --ignore-not-found || true
        
        echo "Waiting for ALB cleanup (60 seconds)..."
        sleep 60
        
        echo "Cleaning up orphaned ALB Security Groups..."
        for sg in $(aws ec2 describe-security-groups --region "$REGION" \
          --filters "Name=tag-key,Values=elbv2.k8s.aws/cluster" \
          --query "SecurityGroups[].GroupId" --output text 2>/dev/null); do
          echo "Deleting Security Group: $sg"
          aws ec2 delete-security-group --group-id "$sg" --region "$REGION" 2>/dev/null || true
        done
      fi
    EOT
    on_failure = continue
  }

  depends_on = [helm_release.aws_load_balancer_controller_tokyo]
}
