# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.112.0"
    }
  }
  #   backend "azurerm" {
  #   subscription_id      = "72e2720e-f496-43c7-ab41-8a74e03960e5"
  #   resource_group_name  = "rg-int-dev-westeurope-001"
  #   storage_account_name = "interntfstatestore"                   
  #   container_name       = "statefilecontainer"
  #   key                  = "jakubkoz/workspace/terrafrom.tfstate"
  #   tenant_id            = "14f31f9a-039a-412c-a460-17911d339497"
  # }
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

variable "KEY_VAULT_RG" {
  description = "keyvault resource group"
  type = string
  default = "group1-keyvault"
}

# Create a resource group
resource "azurerm_resource_group" "resource_group" {
  name     = "group1"
  location = "Poland Central"
}

# Create a vnet
resource "azurerm_virtual_network" "vnet" {
  name                = "${azurerm_resource_group.resource_group.name}_vnet"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  address_space       = ["22.0.0.0/16"]
}

#Create frontend subnet
resource "azurerm_subnet" "frontend_subnet" {
  name                 = "${azurerm_resource_group.resource_group.name}_frontend_subnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["22.0.5.0/24"]
}

#=====================================================

data "azurerm_key_vault" "keyvault" {
  name                = "parkanizer-keyvault"
  resource_group_name = var.KEY_VAULT_RG
}



data "azurerm_key_vault_secret" "database-login" {
  name         = "database-login"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}

output "database-login" {
  value     = data.azurerm_key_vault_secret.database-login.value
  sensitive = true
}

data "azurerm_key_vault_secret" "database-name" {
  name         = "database-name"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}

output "database-name" {
  value     = data.azurerm_key_vault_secret.database-name.value
  sensitive = true
}

data "azurerm_key_vault_secret" "database-password" {
  name         = "database-password"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}

output "database-password" {
  value     = data.azurerm_key_vault_secret.database-password.value
  sensitive = true
}

data "azurerm_key_vault_secret" "docker-password" {
  name         = "docker-password"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}

output "docker-password" {
  value     = data.azurerm_key_vault_secret.docker-password.value
  sensitive = true
}

data "azurerm_key_vault_secret" "docker-username" {
  name         = "docker-username"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}

output "docker-username" {
  value     = data.azurerm_key_vault_secret.docker-username.value
  sensitive = true
}

#=====================================================

module "backend" {
  source = "./modules/backend"
  vnet_name = azurerm_virtual_network.vnet.name
  frontend_subnet = azurerm_subnet.frontend_subnet
  docker_username = var.DOCKER_USERNAME
  docker_password = var.DOCKER_PASSWORD
  depends_on = [ azurerm_resource_group.resource_group ]
}

#========================================================

module "bastion" {
  source = "./modules/bastion"
  vnet_name = azurerm_virtual_network.vnet.name
  depends_on = [ azurerm_resource_group.resource_group ]
}

#====================================================

module "frontend" {
  source = "./modules/frontend"
  vnet_name = azurerm_virtual_network.vnet.name
  docker_password = var.DOCKER_PASSWORD
  docker_username = var.DOCKER_USERNAME
  fronend_subnet_id = azurerm_subnet.frontend_subnet.id
  depends_on = [ azurerm_resource_group.resource_group ]
}

#=====================================================

module "db" {
  source = "./modules/database"
  vnet = azurerm_virtual_network.vnet
  db_connection_subnet_adress_prefixes = ["22.0.3.0/24"]
  db_server_subnet_adress_prefixes = ["22.0.4.0/24"]
  depends_on = [ azurerm_resource_group.resource_group ]
}

#Create subnet for machines to load balancer communication
resource "azurerm_subnet" "monitoring_subnet" {
  name                 = "group1-monitoring-subnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["22.0.10.0/24"]
}

module "monitoring" {
  source = "./modules/monitoring"
  monitoring_subnet_id = azurerm_subnet.monitoring_subnet.id
  docker_password = var.DOCKER_PASSWORD
  docker_username = var.DOCKER_USERNAME
  grafana_username = var.GRAFANA_USERNAME
  grafana_password = var.GRAFANA_PASSWORD
  storage_account_name = azurerm_storage_account.storage_account.name
  storage_account_key = azurerm_storage_account.storage_account.primary_access_key
  container_name = azurerm_storage_container.storage_container.name
  public_key_location = "${path.root}/keys"
  cloud_init_location = "${path.root}/cloud-init-monitoring.yml"
}

# Create storage account wiht blob container for loki logs storage
# resource "azurerm_storage_account" "storage_account" {
#   name                     = "${azurerm_resource_group.resource_group.name}storageaccountlogs" 
#   resource_group_name      = azurerm_resource_group.resource_group.name
#   location                 = azurerm_resource_group.resource_group.location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
# }

# resource "azurerm_storage_container" "storage_container" {
#   name                  = "log-container"
#   storage_account_name  = azurerm_storage_account.storage_account.name
#   container_access_type = "private"
# }

data "azurerm_resource_group" "resource_group_keyvault" {
  name = "group1-keyvault"
}


data "azurerm_storage_account" "storage_account" {
  name                = "group1storageaccountlogs"
  resource_group_name = azurerm_resource_group.resource_group_keyvault.name
}

data "azurerm_storage_container" "storage_container" {
  name                 = "log-container"
  storage_account_name = data.azurerm_storage_account.storage_account.name
}


#=====================================================

# module "acr_peer" {
#   source = "./modules/acr-connection"
#   vnet = azurerm_virtual_network.vnet
#   depends_on = [ azurerm_resource_group.resource_group ]
# }