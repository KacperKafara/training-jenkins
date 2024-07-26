#Create load balancer
resource "azurerm_lb" "load_balancer" {
  name                = "${var.resource_group_name}_lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku = "Standard"
  

  frontend_ip_configuration {
    name                 = "${var.resource_group_name}_lb_frontend_ip"
    subnet_id            = var.frontend_subnet_id
    private_ip_address   = var.frontend_ip
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name            = "${var.resource_group_name}_backend_pool"
  loadbalancer_id = azurerm_lb.load_balancer.id 
}

resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.load_balancer.id
  name                           = "${var.resource_group_name}_lb_rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.load_balancer.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                       = azurerm_lb_probe.probe.id
  disable_outbound_snat          = true
}

resource "azurerm_lb_probe" "probe" {
  loadbalancer_id = azurerm_lb.load_balancer.id
  name            = "${var.resource_group_name}_healthprobe"
  port            = 80
}