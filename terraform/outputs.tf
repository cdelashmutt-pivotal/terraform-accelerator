output "resource_group_name" {
  value = azurerm_resource_group.default.name
}

output "kubernetes_cluster_name" {
  value = azurerm_kubernetes_cluster.default.name
}

output "azure_container_registry_login" {
  value = "az acr login -n ${azurerm_container_registry.default.name}"
}