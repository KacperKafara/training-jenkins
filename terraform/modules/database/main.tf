# Create a vnet
# resource "azurerm_virtual_network" "vnet" {
#   name                = "${var.resource_group_name}_database_vnet"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   address_space       = var.vnet_adress_space
# }

# Define a subnet for database
resource "azurerm_subnet" "postgres_subnet" {
  name                 = "${var.resource_group_name}_postgres_subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet.name
  address_prefixes     = var.db_server_subnet_adress_prefixes
  # service_endpoints    = ["Microsoft.Storage"]
  # delegation {
  #   name = "fs"
  #   service_delegation {
  #     name = "Microsoft.DBforPostgreSQL/flexibleServers"
  #     actions = [
  #       "Microsoft.Network/virtualNetworks/subnets/join/action",
  #     ]
  #   }
  # }
}

# # Define a subnet for backend to connect with databse
# resource "azurerm_subnet" "backend_database_subnet" {
#   name                 = "${var.resource_group_name}_backend_database_subnet"
#   resource_group_name  = var.resource_group_name
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   address_prefixes     = var.db_connection_subnet_adress_prefixes
# }

resource "azurerm_private_dns_zone" "dns" {
  name                = "${var.resource_group_name}.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_vnet_link" {
  name                  = "${var.resource_group_name}VnetZone.com"
  private_dns_zone_name = azurerm_private_dns_zone.dns.name
  virtual_network_id    = var.vnet.id
  resource_group_name   = var.resource_group_name
}

# Define a PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "postgres_server" {
  name                = "${var.resource_group_name}-postgresql-server"
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = "16"
  zone                = "1"

  administrator_login          = var.database_login
  administrator_password       = var.database_password
  sku_name                     = "GP_Standard_D2s_v3"
  #delegated_subnet_id = azurerm_subnet.postgres_subnet.id
  private_dns_zone_id = azurerm_private_dns_zone.dns.id
  public_network_access_enabled = false

  # prevent the possibility of accidental data loss
#   lifecycle {
#     prevent_destroy = true
#   }
}

# Define a PostgreSQL Flexible Server Database
resource "azurerm_postgresql_flexible_server_database" "postgres_database" {
  name                = var.database_name
  server_id           = azurerm_postgresql_flexible_server.postgres_server.id

  # prevent the possibility of accidental data loss
#   lifecycle {
#     prevent_destroy = true
#   }
}

# Create private endpoint for SQL server
resource "azurerm_private_endpoint" "database_private_endpoint" {
  name                = "${var.resource_group_name}_endpoint_sql"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.postgres_subnet.id

  private_service_connection {
    name                           = "${var.resource_group_name}_private_serviceconnection"
    private_connection_resource_id = azurerm_postgresql_flexible_server.postgres_server.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns.id]
  }
}

# # Create Network Security Group for backend connection database and rules
# resource "azurerm_network_security_group" "backend_database_subnet_nsg" {
#   name                = "${var.resource_group_name}_backend_database_nsg"
#   location            = var.location
#   resource_group_name = var.resource_group_name

#   security_rule {
#     name                       = "db-access-ingress"
#     priority                   = 1008
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp" 
#     source_port_range          = "5432"
#     destination_port_range     = "*"
#     source_address_prefix      = azurerm_subnet.backend_database_subnet.address_prefixes[0]
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

# Create Network Security Group for postgres to reach backend and rules
# resource "azurerm_network_security_group" "postgres_subnet_nsg" {
#   name                = "${var.resource_group_name}_postgres_nsg"
#   location            = var.location
#   resource_group_name = var.resource_group_name

#   security_rule {
#     name                       = "db-access-ingress"
#     priority                   = 100
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "5432"
#     source_address_prefix      = azurerm_subnet.backend_database_subnet.address_prefixes[0]
#     destination_address_prefix = azurerm_subnet.postgres_subnet.address_prefixes[0]
#   }

#   security_rule  {
#     name                       = "denyAllIngress"
#     priority                   = 200
#     direction                  = "Inbound"
#     access                     = "Deny"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "*"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
# }

# # Bind Network Security Groups with subnets 
# resource "azurerm_subnet_network_security_group_association" "backend_nsg_association" {
#   subnet_id                 = azurerm_subnet.backend_database_subnet.id
#   network_security_group_id = azurerm_network_security_group.backend_database_subnet_nsg.id
# }

# resource "azurerm_subnet_network_security_group_association" "postgres_nsg_association" {
#   subnet_id                 = azurerm_subnet.postgres_subnet.id
#   network_security_group_id = azurerm_network_security_group.postgres_subnet_nsg.id
# }