resource "kubernetes_manifest" "argocd_app_seoul" {
  provider = kubernetes.seoul

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = module.eks_seoul.cluster_name
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.git_repo_url
        path           = "k8s/overlays/${var.env}"
        targetRevision = var.git_repo_revision
      }
      destination = {
        server    = module.eks_seoul.cluster_arn
        namespace = "lionpay"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }

  depends_on = [aws_eks_capability.argocd_seoul]
}

resource "kubernetes_manifest" "argocd_app_tokyo" {
  provider = kubernetes.seoul

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = module.eks_tokyo.cluster_name
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.git_repo_url
        path           = "k8s/overlays/${var.env}"
        targetRevision = var.git_repo_revision
      }
      destination = {
        server    = module.eks_tokyo.cluster_arn
        namespace = "lionpay"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }

  depends_on = [aws_eks_capability.argocd_seoul]
}
