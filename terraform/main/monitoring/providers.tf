terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
      configuration_aliases = [ helm.seoul, helm.tokyo ]
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      configuration_aliases = [ kubernetes.seoul, kubernetes.tokyo ]
    }
  }
}
