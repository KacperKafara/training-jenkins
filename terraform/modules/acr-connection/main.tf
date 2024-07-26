data "azurerm_resource_group" "hub_resource_group" {
  name = "rg-int-dev-westeurope-001"
}

data "azurerm_virtual_network" "hub_vnet" {
  name = "vnet-hub-int-dev-westeurope-001"
  resource_group_name = data.azurerm_resource_group.hub_resource_group.name
}


# Create peerings between main vnet and acr hub vnet
resource "azurerm_virtual_network_peering" "inside_vnet_to_acr_hub_vnet" {
  name                      = "${var.resource_group_name}_acr_hub_vnet_peer"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = var.location
  remote_virtual_network_id = data.azurerm_virtual_network.hub_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "acr_hub_vnet_to_inside_vnet" {
  name                      = "group-1-vnet-peer"
  resource_group_name       = data.azurerm_resource_group.hub_resource_group.name
  virtual_network_name      = data.azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = var.vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Add link to the private dns zone of acr hub vnet
data "azurerm_private_dns_zone" "private_dns_zone" {
  name                = "privatelink.azurecr.io"
  resource_group_name = data.azurerm_resource_group.hub_resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_network_link" {
  name                  = "${var.resource_group_name}_dns_network_link"
  resource_group_name   = data.azurerm_resource_group.hub_resource_group.name
  private_dns_zone_name = data.azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = var.vnet_id
}