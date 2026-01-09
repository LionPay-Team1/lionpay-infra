###############################################################
# ArgoCD Applications - Deploy via kubectl
###############################################################

resource "null_resource" "argocd_app_seoul" {
  depends_on = [aws_eks_capability.argocd_seoul]

  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig --name ${module.eks_seoul.cluster_name} --region ap-northeast-2 --alias ${module.eks_seoul.cluster_name}
      
      cat <<EOF | kubectl apply -f - --context ${module.eks_seoul.cluster_name}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${module.eks_seoul.cluster_name}
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${var.git_repo_url}
    path: k8s/overlays/${var.env}
    targetRevision: ${var.git_repo_revision}
  destination:
    server: ${module.eks_seoul.cluster_arn}
    namespace: lionpay
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
    EOT
  }

  triggers = {
    cluster_name      = module.eks_seoul.cluster_name
    cluster_arn       = module.eks_seoul.cluster_arn
    git_repo_url      = var.git_repo_url
    git_repo_revision = var.git_repo_revision
    env               = var.env
  }
}

resource "null_resource" "argocd_app_tokyo" {
  depends_on = [aws_eks_capability.argocd_seoul]

  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig --name ${module.eks_seoul.cluster_name} --region ap-northeast-2 --alias ${module.eks_seoul.cluster_name}
      
      cat <<EOF | kubectl apply -f - --context ${module.eks_seoul.cluster_name}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${module.eks_tokyo.cluster_name}
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${var.git_repo_url}
    path: k8s/overlays/${var.env}
    targetRevision: ${var.git_repo_revision}
  destination:
    server: ${module.eks_tokyo.cluster_arn}
    namespace: lionpay
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
    EOT
  }

  triggers = {
    cluster_name      = module.eks_tokyo.cluster_name
    cluster_arn       = module.eks_tokyo.cluster_arn
    git_repo_url      = var.git_repo_url
    git_repo_revision = var.git_repo_revision
    env               = var.env
  }
}

