#Create subnet for machines to load balancer communication
resource "azurerm_subnet" "backend_subnet" {
  name                 = "${var.resource_group_name}_backend_subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = ["22.0.1.0/24"]
}

# Associate Network Interface to the Backend Pool of the Load Balancer
resource "azurerm_network_interface_backend_address_pool_association" "lb_pool_nic_association" {
  count = length(module.vm.load_balancer_nic)
  network_interface_id    = module.vm.load_balancer_nic[count.index].id
  ip_configuration_name   = module.vm.load_balancer_nic[count.index].ip_configuration[0].name
  backend_address_pool_id = module.lb.backend_address_pool_id
}

# Create Network Security Group and rules
resource "azurerm_network_security_group" "backend_nsg" {
  name                = "${var.resource_group_name}_backend_nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "web"
    priority                   = 1008
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = var.frontend_subnet.address_prefixes[0]
  }
}

# Associate the Network Security Group to the subnet
resource "azurerm_subnet_network_security_group_association" "backend_nsg_association" {
  subnet_id                 = azurerm_subnet.backend_subnet.id
  network_security_group_id = azurerm_network_security_group.backend_nsg.id
}


module "vm" {
  source = "./modules/virtual-machine"
  load_balancer_subnet_id = azurerm_subnet.backend_subnet.id
  docker_password = var.docker_password
  docker_username = var.docker_username
  public_key_location = "${path.root}/keys"
  cloud_init_location = "${path.module}/cloud-init.yml"
  depends_on = [ module.nat ]
}

module "lb" {
  source = "./modules/load-balancer"
  backend_subnet_id  = azurerm_subnet.backend_subnet.id
  frontend_subnet_id = var.frontend_subnet.id
  frontend_ip        = var.frontend_ip
}

module "nat" {
  source = "./modules/nat-gateway"
  backend_subnet_id  = azurerm_subnet.backend_subnet.id
}