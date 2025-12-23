resource "aws_eks_capability" "argocd" {
  cluster_name              = module.eks_blueprints.cluster_name
  capability_name           = "argocd"
  type                      = "ARGOCD"
  role_arn                  = var.argocd_capability_role_arn
  delete_propagation_policy = "RETAIN"

  configuration {
    argo_cd {
      aws_idc {
        idc_instance_arn = var.idc_instance_arn
      }
      namespace = var.argocd_namespace
    }
  }

  tags = {
    Name = "${module.eks_blueprints.cluster_name}-argocd-capability"
  }
}
