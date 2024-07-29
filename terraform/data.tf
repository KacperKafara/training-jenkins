# data "azurerm_resource_group" "hub_resource_group" {
#   name = "rg-int-dev-westeurope-001"
# }

# data "azurerm_virtual_network" "hub_vnet" {
#   name = "vnet-hub-int-dev-westeurope-001"
#   resource_group_name = data.azurerm_resource_group.hub_resource_group.name
# }

# data "azurerm_private_dns_zone" "private_dns_zone" {
#   name                = "privatelink.azurecr.io"
#   resource_group_name = data.azurerm_resource_group.hub_resource_group.name
# }
