###############################################################
# ArgoCD Applications - Deploy via kubectl
###############################################################

resource "null_resource" "argocd_apps" {
  depends_on = [aws_eks_capability.argocd_seoul]

  triggers = {
    seoul_cluster_name = module.eks_seoul.cluster_name
    seoul_cluster_arn  = module.eks_seoul.cluster_arn
    tokyo_cluster_name = module.eks_tokyo.cluster_name
    tokyo_cluster_arn  = module.eks_tokyo.cluster_arn
    git_repo_url       = var.git_repo_url
    git_repo_revision  = var.git_repo_revision
    env                = var.env
    argocd_role_arn    = aws_iam_role.argocd_capability.arn
  }

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

  # Cleanup on destroy
  provisioner "local-exec" {
    when       = destroy
    command    = <<-EOT
      SEOUL_CLUSTER="${try(self.triggers.seoul_cluster_name, "")}"
      TOKYO_CLUSTER="${try(self.triggers.tokyo_cluster_name, "")}"
      ROLE_ARN="${try(self.triggers.argocd_role_arn, "")}"

      if [ -n "$SEOUL_CLUSTER" ]; then
        # Update kubeconfig for Seoul cluster
        aws eks update-kubeconfig --name "$SEOUL_CLUSTER" --region ap-northeast-2 --alias "$SEOUL_CLUSTER" || true

        # Delete ArgoCD Applications first (this will trigger cascade delete of managed resources)
        kubectl delete application "$SEOUL_CLUSTER" -n argocd --context "$SEOUL_CLUSTER" --ignore-not-found || true
        kubectl delete application "$TOKYO_CLUSTER" -n argocd --context "$SEOUL_CLUSTER" --ignore-not-found || true

        # Wait for applications to be fully deleted
        sleep 10

        # Delete cluster secrets
        kubectl delete secret "$SEOUL_CLUSTER" -n argocd --context "$SEOUL_CLUSTER" --ignore-not-found || true
        kubectl delete secret "$TOKYO_CLUSTER" -n argocd --context "$SEOUL_CLUSTER" --ignore-not-found || true

        # Delete lionpay namespace resources on both clusters (cleanup any remaining resources)
        kubectl delete all --all -n lionpay --context "$SEOUL_CLUSTER" --ignore-not-found || true
      fi

      if [ -n "$TOKYO_CLUSTER" ]; then
        aws eks update-kubeconfig --name "$TOKYO_CLUSTER" --region ap-northeast-1 --alias "$TOKYO_CLUSTER" || true
        kubectl delete all --all -n lionpay --context "$TOKYO_CLUSTER" --ignore-not-found || true
      fi

      # Remove EKS Access Entries for ArgoCD capability role (only if role ARN exists)
      if [ -n "$ROLE_ARN" ] && [ -n "$SEOUL_CLUSTER" ]; then
        aws eks delete-access-entry --region ap-northeast-2 --cluster-name "$SEOUL_CLUSTER" --principal-arn "$ROLE_ARN" --no-cli-pager || true
      fi
      if [ -n "$ROLE_ARN" ] && [ -n "$TOKYO_CLUSTER" ]; then
        aws eks delete-access-entry --region ap-northeast-1 --cluster-name "$TOKYO_CLUSTER" --principal-arn "$ROLE_ARN" --no-cli-pager || true
      fi
    EOT
    on_failure = continue
  }
}

