terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.66.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.3"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    tanzu-mission-control = {
      source = "vmware/tanzu-mission-control"
      version = ">= 1.1.5"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.15.0"
    }
  }

  required_version = ">= 0.14"
}

## Temporarily store the cluster kubeconfig
## The referenced object is in aks-cluster.tf
resource "local_file" "kubeconfig" {
  content  = azurerm_kubernetes_cluster.default.kube_config_raw
  filename = "${path.root}/.terraform/tmp/${var.project_name}-kubeconfig"
}

provider "kubernetes" {
  config_path = local_file.kubeconfig.filename
}

provider "kubectl" {
  config_path = local_file.kubeconfig.filename
}

provider "azurerm" {
  features {}
}