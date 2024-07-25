# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.112.0"
    }
  }
    backend "azurerm" {
    subscription_id      = "72e2720e-f496-43c7-ab41-8a74e03960e5"
    resource_group_name  = "rg-int-dev-westeurope-001"
    storage_account_name = "interntfstatestore"                   
    container_name       = "statefilecontainer"
    key                  = "jakubkoz/workspace/terrafrom.tfstate"
    tenant_id            = "14f31f9a-039a-412c-a460-17911d339497"
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

variable "DOCKER_USERNAME" {
  description = "acr username"
  type = string
  default = "username"
}

variable "DOCKER_PASSWORD" {
  description = "acr password"
  type = string
  default = "password"
}

variable "DATABASE_LOGIN" {
  description = "postgres admin login"
  type = string
  default = "username"
}

variable "DATABASE_PASSWORD" {
  description = "postgres admin password"
  type = string
  default = "password"
}

variable "DATABASE_NAME" {
  description = "postgres database name"
  type = string
  default = "parkingDb"
}

# Create a resource group
resource "azurerm_resource_group" "resource_group" {
  name     = "group1"
  location = "Poland Central"
}

# Create a vnet
resource "azurerm_virtual_network" "vnet" {
  name                = "jk-example-vnet"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  address_space       = ["22.0.0.0/16"]
}

#Create subnet for machines to load balancer communication
resource "azurerm_subnet" "subnet" {
  name                 = "jk-example-subnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["22.0.1.0/24"]
}

#Create frontend subnet
resource "azurerm_subnet" "frontend_subnet" {
  name                 = "jk-example-frontend-subnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["22.0.5.0/24"]
}

#=====================================================

#Create load balancer
resource "azurerm_lb" "load_balancer" {
  name                = "jk-example-lb"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku = "Standard"
  

  frontend_ip_configuration {
    name                 = "jk-example-lb-frontend-ip"
    subnet_id            = azurerm_subnet.frontend_subnet.id
    private_ip_address   = "22.0.5.4"
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.load_balancer.id
  name                           = "jk-example-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.load_balancer.frontend_ip_configuration[0].name
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id = azurerm_lb_probe.probe.id
  disable_outbound_snat          = true
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name            = "jk-example-backend-pool"
  loadbalancer_id = azurerm_lb.load_balancer.id 
}


resource "azurerm_lb_probe" "probe" {
  loadbalancer_id = azurerm_lb.load_balancer.id
  name            = "jk-example-healthprobe"
  port            = 80
}


# Associate Network Interface to the Backend Pool of the Load Balancer
resource "azurerm_network_interface_backend_address_pool_association" "lb_pool_nic_association" {
  count = length(module.vm.load_balancer_nic)
  network_interface_id    = module.vm.load_balancer_nic[count.index].id
  ip_configuration_name   = module.vm.load_balancer_nic[count.index].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}

# Create Network Security Group and rules
resource "azurerm_network_security_group" "backend_nsg" {
  name                = "jk-example-nsg"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  security_rule {
    name                       = "web"
    priority                   = 1008
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "22.0.1.0/24"
  }
}

# Associate the Network Security Group to the subnet
resource "azurerm_subnet_network_security_group_association" "my_nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.backend_nsg.id
}

#========================================================

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["22.0.9.0/24"]
}

resource "azurerm_public_ip" "bastion_public_ip" {
  name                = "jk-example-bastion-public-ip"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion_host" {
  name                = "jk-example-bastion-host"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_public_ip.id
  }
}


#=====================================================

#Create NAT gateway
resource "azurerm_nat_gateway" "gateway" {
  name                      = "jk-example-gateway"
  location                  = azurerm_resource_group.resource_group.location
  resource_group_name       = azurerm_resource_group.resource_group.name
  idle_timeout_in_minutes   = 10
  sku_name = "Standard"
}

#Create public ip for nat gateway
resource "azurerm_public_ip" "gateway_public_ip" {
  name                = "jk-example-gw-public-ip"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
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
  subnet_id      = azurerm_subnet.subnet.id
  nat_gateway_id = azurerm_nat_gateway.gateway.id
}

#Create public ip for frontend
resource "azurerm_public_ip" "frontend_public_ip" {
  name                = "jk-example-frontend-public-ip"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  domain_name_label   = "group1-parkanizer"
  sku = "Standard"
}

#Create nic for vm3
resource "azurerm_network_interface" "vm3_nic1" {
  name                = "jk-example-vm3-nic1"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id = azurerm_subnet.frontend_subnet.id
    public_ip_address_id = azurerm_public_ip.frontend_public_ip.id
  }
}

# Create security group for frontend
resource "azurerm_network_security_group" "frontend_sg" {
  name                = "frontend-sg"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  security_rule {
    name                       = "frontend-HTTP-rule"
    priority                   = 1008
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "frontend-HTTPS-rule"
    priority                   = 1018
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate the Network Security Group to the subnet
resource "azurerm_subnet_network_security_group_association" "my_frontend_sg_association" {
  subnet_id                 = azurerm_subnet.frontend_subnet.id
  network_security_group_id = azurerm_network_security_group.frontend_sg.id
}

#Create vm 3 (frontend)
resource "azurerm_linux_virtual_machine" "vm3-frontend" {
  name                = "jk-example-vm3-frontend"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  size                = "Standard_F1"
  admin_username      = "adminusername"

  network_interface_ids = [
    azurerm_network_interface.vm3_nic1.id,
  ]

  admin_ssh_key {
    username   = "adminusername"
    public_key = file("keys/key_vm2.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("cloud-init2.yml", {
       DOCKER_USERNAME = var.DOCKER_USERNAME,
       DOCKER_PASSWORD = var.DOCKER_PASSWORD
     }))
}

#==========================================================

module "vm" {
  source = "./modules/virtual-machine"
  load_balancer_subnet_id = azurerm_subnet.subnet.id
  #database_subnet_id = module.db.databse_connection_subnet_id
  docker_password = var.DOCKER_PASSWORD
  docker_username = var.DOCKER_USERNAME
  public_key_location = "${path.root}/keys"
  cloud_init_location = "${path.root}/cloud-init.yml"
}

#==============================================

data "azurerm_resource_group" "hub_resource_group" {
  name = "rg-int-dev-westeurope-001"
}

data "azurerm_virtual_network" "hub_vnet" {
  name = "vnet-hub-int-dev-westeurope-001"
  resource_group_name = data.azurerm_resource_group.hub_resource_group.name
}


# Create peerings between main vnet and acr hub vnet
resource "azurerm_virtual_network_peering" "inside_vnet_to_acr_hub_vnet" {
  name                      = "acr-hub-vnet-peer"
  resource_group_name       = azurerm_resource_group.resource_group.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
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
  remote_virtual_network_id = azurerm_virtual_network.vnet.id

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
  name                  = "group1_dns_network_link"
  resource_group_name   = data.azurerm_resource_group.hub_resource_group.name
  private_dns_zone_name = data.azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

module "db" {
  source = "./modules/database"
  vnet = azurerm_virtual_network.vnet
  db_connection_subnet_adress_prefixes = ["22.0.3.0/24"]
  db_server_subnet_adress_prefixes = ["22.0.4.0/24"]
  depends_on = [ azurerm_resource_group.resource_group ]
}
