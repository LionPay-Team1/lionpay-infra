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

  depends_on = [module.karpenter_tokyo]
}
