resource "tanzu-mission-control_cluster_group" "cluster_group" {
  name = var.project_name
  meta {
    description = "Cluster group for ${var.project_name} clusters"
  }
}

resource "tanzu-mission-control_cluster" "attach_aks_cluster_with_kubeconfig" {
  management_cluster_name = "attached"     # Default: attached
  provisioner_name        = "attached"     # Default: attached
  name                    = azurerm_kubernetes_cluster.default.name # Required

  attach_k8s_cluster {
    kubeconfig_file = local_file.kubeconfig.filename # Required
    description     = "temporary kubeconfig"
  }

  meta {
    description = "${var.project_name} clusters"
    labels      = { "type" : "${var.project_name}" }
  }

  spec {
    cluster_group = tanzu-mission-control_cluster_group.cluster_group.name
  }

}