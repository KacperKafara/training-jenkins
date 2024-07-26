#Create NAT gateway
resource "azurerm_nat_gateway" "gateway" {
  name                      = "${var.resource_group_name}_nat_gateway"
  location                  = var.location
  resource_group_name       = var.resource_group_name
  idle_timeout_in_minutes   = 10
  sku_name = "Standard"
}

#Create public ip for nat gateway
resource "azurerm_public_ip" "gateway_public_ip" {
  name                = "${var.resource_group_name}_gw_public_ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku = "Standard"
}

#Connect public ip to nat gateway
resource "azurerm_nat_gateway_public_ip_association" "gateway_public_ip_association" {
  nat_gateway_id       = azurerm_nat_gateway.gateway.id
  public_ip_address_id = azurerm_public_ip.gateway_public_ip.id
}

#Connect subnet to nat gateway
resource "azurerm_subnet_nat_gateway_association" "gateway_subnet_association" {
  subnet_id      = var.backend_subnet_id
  nat_gateway_id = azurerm_nat_gateway.gateway.id
}