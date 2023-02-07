resource "tanzu-mission-control_cluster_group" "cluster_group" {
  name = local.project_name
  meta {
    description = "Cluster group for ${local.project_name} clusters"
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
    description = "${local.project_name} clusters"
    labels      = { "type" : "${local.project_name}" }
  }

  spec {
    cluster_group = tanzu-mission-control_cluster_group.cluster_group.name
  }

}