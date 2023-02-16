# Query the current master zone
data "azurerm_resource_group" "parent" {
  name = var.dns_parent_zone_rg
}
data "azurerm_dns_zone" "parent" {
  name = var.dns_parent_zone_name
}

resource "azurerm_dns_zone" "dns" {
  name                = "${var.project_name}.${data.azurerm_dns_zone.parent.name}"
  resource_group_name = azurerm_resource_group.default.name
}

# create ns record for sub-zone in parent zone
resource "azurerm_dns_ns_record" "dns" {
  name                = var.project_name
  zone_name           = data.azurerm_dns_zone.parent.name
  resource_group_name = data.azurerm_dns_zone.parent.resource_group_name
  ttl                 = 60

  records = azurerm_dns_zone.dns.name_servers
}

resource "azuread_application" "external_dns" {
  display_name = "${var.project_name}-external-dns"
  owners = [data.azuread_client_config.current.object_id]
}

resource "azuread_application_password" "external_dns" {
  application_object_id = azuread_application.external_dns.object_id
}

resource "azuread_service_principal" "external_dns" {
  application_id = azuread_application.external_dns.application_id
  owners = [data.azuread_client_config.current.object_id]
}

resource "azurerm_role_assignment" "resource_group_reader" {
  scope                = azurerm_resource_group.default.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.external_dns.id
}

resource "azurerm_role_assignment" "dns_contributer" {
  scope                = azurerm_dns_zone.dns.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azuread_service_principal.external_dns.id
}