###############################################################
# ArgoCD Applications - Deploy via kubectl
###############################################################

resource "null_resource" "argocd_apps" {
  depends_on = [aws_eks_capability.argocd_seoul]

  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig --name ${module.eks_seoul.cluster_name} --region ap-northeast-2 --alias ${module.eks_seoul.cluster_name}

      # Ensure ArgoCD capability role can access target clusters (EKS Access Entries)
      ROLE_ARN="${aws_iam_role.argocd_capability.arn}"

      ensure_access() {
        local region="$1" cluster="$2"

        if aws eks list-access-entries --region "$region" --cluster-name "$cluster" --query 'accessEntries' --output text --no-cli-pager | grep -q "$ROLE_ARN"; then
          :
        else
          aws eks create-access-entry --region "$region" --cluster-name "$cluster" --principal-arn "$ROLE_ARN" --type STANDARD --no-cli-pager
        fi

        if aws eks list-associated-access-policies --region "$region" --cluster-name "$cluster" --principal-arn "$ROLE_ARN" --query 'associatedAccessPolicies[].policyArn' --output text --no-cli-pager | grep -q 'AmazonEKSClusterAdminPolicy'; then
          :
        else
          aws eks associate-access-policy --region "$region" --cluster-name "$cluster" --principal-arn "$ROLE_ARN" --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy --access-scope type=cluster --no-cli-pager
        fi
      }

      ensure_access ap-northeast-2 ${module.eks_seoul.cluster_name}
      ensure_access ap-northeast-1 ${module.eks_tokyo.cluster_name}

      # Register target clusters in ArgoCD (cluster secrets)
      cat <<EOF | kubectl apply -f - --context ${module.eks_seoul.cluster_name}
apiVersion: v1
kind: Secret
metadata:
  name: ${module.eks_seoul.cluster_name}
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
stringData:
  name: ${module.eks_seoul.cluster_name}
  server: ${module.eks_seoul.cluster_arn}
  project: default
---
apiVersion: v1
kind: Secret
metadata:
  name: ${module.eks_tokyo.cluster_name}
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
stringData:
  name: ${module.eks_tokyo.cluster_name}
  server: ${module.eks_tokyo.cluster_arn}
  project: default
---
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
    name: ${module.eks_seoul.cluster_name}
    namespace: lionpay
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
---
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
    name: ${module.eks_tokyo.cluster_name}
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
    seoul_cluster_name = module.eks_seoul.cluster_name
    seoul_cluster_arn  = module.eks_seoul.cluster_arn
    tokyo_cluster_name = module.eks_tokyo.cluster_name
    tokyo_cluster_arn  = module.eks_tokyo.cluster_arn
    git_repo_url       = var.git_repo_url
    git_repo_revision  = var.git_repo_revision
    env                = var.env
  }
}

