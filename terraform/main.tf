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
  backend_port                   = 8080
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
resource "azurerm_network_interface_backend_address_pool_association" "lb_pool_nic_association" {
  count = length(module.vm.load_balancer_nic)
  network_interface_id    = module.vm.load_balancer_nic[count.index].id
  ip_configuration_name   = module.vm.load_balancer_nic[count.index].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}

# # Associate Network Interface to the Backend Pool of the Load Balancer
# resource "azurerm_network_interface_backend_address_pool_association" "lb_pool_nic_association_vm1" {
#   network_interface_id    = azurerm_network_interface.vm1_nic1.id
#   ip_configuration_name   = azurerm_network_interface.vm1_nic1.ip_configuration[0].name
#   backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
# }

# Associate Network Interface to the Backend Pool of the Load Balancer
# resource "azurerm_network_interface_backend_address_pool_association" "lb_pool_nic_association_vm2" {
#   network_interface_id    = azurerm_network_interface.vm2_nic1.id
#   ip_configuration_name   = azurerm_network_interface.vm2_nic1.ip_configuration[0].name
#   backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
# }

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

module "db" {
  source = "./modules/database"
  vnet = azurerm_virtual_network.vnet
  db_connection_subnet_adress_prefixes = ["22.0.3.0/24"]
  db_server_subnet_adress_prefixes = ["22.0.4.0/24"]
}

# # Create Network Security Group for backend connection database and rules
# resource "azurerm_network_security_group" "backend_database_subnet_nsg" {
#   name                = "jk-example-backend-database-nsg"
#   location            = azurerm_resource_group.resource_group.location
#   resource_group_name = azurerm_resource_group.resource_group.name

#   security_rule {
#     name                       = "db-access-ingress"
#     priority                   = 1008
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp" 
#     source_port_range          = "*"
#     destination_port_range     = "*"
#     source_address_prefix      = "5432"
#     destination_address_prefix = azurerm_subnet.backend_database_subnet.address_prefixes[0]
#   }

#   security_rule {
#     name                       = "db-access-egress"
#     priority                   = 1008
#     direction                  = "Outbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "5432"
#     source_address_prefix      = "*"
#     destination_address_prefix = azurerm_subnet.postgres_subnet.address_prefixes[0]
#   }
# }

# # Create Network Security Group for postgres to reach backend and rules
# resource "azurerm_network_security_group" "postgres_subnet_nsg" {
#   name                = "jk-example-postgres-nsg"
#   location            = azurerm_resource_group.resource_group.location
#   resource_group_name = azurerm_resource_group.resource_group.name

#   security_rule {
#     name                       = "db-access-egress"
#     priority                   = 1008
#     direction                  = "Outbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "*"
#     source_address_prefix      = "5432"
#     destination_address_prefix = azurerm_subnet.backend_database_subnet.address_prefixes[0]
#   }
#   security_rule  {
#     name                       = "db-access-ingress"
#     priority                   = 1008
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "5432"
#     source_address_prefix      = "*"
#     destination_address_prefix = azurerm_subnet.postgres_subnet.address_prefixes[0]
#   }
# }

# Bind Network Security Groups with subnets 
# resource "azurerm_subnet_network_security_group_association" "backend_nsg_association" {
#   subnet_id                 = azurerm_subnet.backend_database_subnet.id
#   network_security_group_id = azurerm_network_security_group.backend_database_subnet_nsg.id
# }

# resource "azurerm_subnet_network_security_group_association" "postgres_nsg_association" {
#   subnet_id                 = azurerm_subnet.postgres_subnet.id
#   network_security_group_id = azurerm_network_security_group.postgres_subnet_nsg.id
# }
