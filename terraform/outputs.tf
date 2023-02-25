output "resource_group_name" {
  value = azurerm_resource_group.default.name
}

output "kubernetes_cluster_name" {
  value = azurerm_kubernetes_cluster.default.name
}

output "az_cluster_creds_command" {
  description = "The `az` cli command to get the admin credentials for the AKS cluster"
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.default.name} --name ${azurerm_kubernetes_cluster.default.name} --admin"
}

output "azure_container_registry_login" {
  value = "az acr login -n ${azurerm_container_registry.default.name}"
}

output "view_cluster_registration" {
  description = "Add this to your TAP Values for installing the tap package, under the `tap_gui.app_config.kubernetes.clusterLocatorMethods[].clusters` key to register this cluster with your view cluster"
  value = <<YAML
    - url: ${azurerm_kubernetes_cluster.default.fqdn}
      name: ${azurerm_kubernetes_cluster.default.name}
      authProvider: serviceAccount
      serviceAccountToken: ${kubernetes_secret_v1.tap-gui-viewer.data.token}
      skipTLSVerify: true
  YAML
  sensitive = true
}