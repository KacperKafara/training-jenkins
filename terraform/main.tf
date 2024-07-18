# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
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

# Create a resource group
resource "azurerm_resource_group" "resource_group" {
  name     = "jk-example-resource-group2"
  location = "Poland Central"
}

# Create a vnet
resource "azurerm_virtual_network" "vnet" {
  name                = "jk-example-vnet"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  address_space       = ["10.0.0.0/16"]
}

#Create subnet for machines to load balancer communication
resource "azurerm_subnet" "subnet" {
  name                 = "jk-example-subnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

#=====================================================

#Create public ip for load balancer
resource "azurerm_public_ip" "load_balancer_public_ip" {
  name                = "jk-example-lb-public-ip"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  sku = "Standard"
}

#Create load balancer
resource "azurerm_lb" "load_balancer" {
  name                = "jk-example-lb"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku = "Standard"
  

  frontend_ip_configuration {
    name                 = "jk-example-lb-frontend-ip"
    public_ip_address_id = azurerm_public_ip.load_balancer_public_ip.id
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

# # Create Network Interface
# resource "azurerm_network_interface" "pool_nic" {
#   name                = "jk-backend-pool-nic"
#   location            = azurerm_resource_group.resource_group.location
#   resource_group_name = azurerm_resource_group.resource_group.name

#   ip_configuration {
#     name                          = "jk-example-ipconfig-pool"
#     subnet_id                     = azurerm_subnet.subnet.id
#     private_ip_address_allocation = "Dynamic"
#     primary = true
#   }
# }

# Associate Network Interface to the Backend Pool of the Load Balancer
resource "azurerm_network_interface_backend_address_pool_association" "lb_pool_nic_association_vm1" {
  network_interface_id    = azurerm_network_interface.vm1_nic1.id
  ip_configuration_name   = azurerm_network_interface.vm1_nic1.ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}

# Associate Network Interface to the Backend Pool of the Load Balancer
resource "azurerm_network_interface_backend_address_pool_association" "lb_pool_nic_association_vm2" {
  network_interface_id    = azurerm_network_interface.vm2_nic1.id
  ip_configuration_name   = azurerm_network_interface.vm2_nic1.ip_configuration[0].name
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
    destination_address_prefix = "10.0.1.0/24"
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
  address_prefixes     = ["10.0.9.0/24"]
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

#==========================================================

#Create nic for vm1
resource "azurerm_network_interface" "vm1_nic1" {
  name                = "jk-example-vm1-nic1"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

#Create nic for vm2
resource "azurerm_network_interface" "vm2_nic1" {
  name                = "jk-example-vm2-nic1"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

#Create vm 1
resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "jk-example-vm1"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  size                = "Standard_F1"
  admin_username      = "adminusername"
  network_interface_ids = [
    azurerm_network_interface.vm1_nic1.id,
  ]

  admin_ssh_key {
    username   = "adminusername"
    public_key = file("keys/key_vm1.pub")
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
}

#Create vm
resource "azurerm_linux_virtual_machine" "vm2" {
  name                = "jk-example-vm2"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  size                = "Standard_F1"
  admin_username      = "adminusername"
  network_interface_ids = [
    azurerm_network_interface.vm2_nic1.id,
  ]

  admin_ssh_key {
    username   = "adminusername"
    public_key = file("keys//key_vm2.pub")
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
}