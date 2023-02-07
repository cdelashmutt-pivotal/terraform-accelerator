locals {
  project_name = "example-project"
}

resource "azurerm_resource_group" "default" {
  name     = "${local.project_name}-rg"
  location = "East US 2"

  tags = {
    environment = "Demo"
  }
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = "${local.project_name}-aks"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  dns_prefix          = "${local.project_name}-k8s"

  default_node_pool {
    name            = "default"
    node_count      = 4
    vm_size         = "Standard_B2ms"
    os_disk_size_gb = 80
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control {
    enabled = true
  }

  tags = {
    environment = "Demo"
  }
}

resource "random_string" "resource_code" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_container_registry" "default" {
  name                = "tapregistry${random_string.resource_code.result}"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_role_assignment" "cluster-acr-role-pull" {
  principal_id                     = azurerm_kubernetes_cluster.default.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.default.id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "cluster-acr-role-push" {
  principal_id                     = azurerm_kubernetes_cluster.default.kubelet_identity[0].object_id
  role_definition_name             = "AcrPush"
  scope                            = azurerm_container_registry.default.id
  skip_service_principal_aad_check = true
}