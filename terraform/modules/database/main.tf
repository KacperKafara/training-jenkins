# Define a subnet for database
resource "azurerm_subnet" "postgres_subnet" {
  name                 = "${var.resource_group_name}_postgres_subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet.name
  address_prefixes     = var.db_server_subnet_adress_prefixes
}

resource "azurerm_private_dns_zone" "dns" {
  name                = "${var.resource_group_name}.azure.com"
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
  sku_name                     = "B_Standard_B1ms"
  #delegated_subnet_id = azurerm_subnet.postgres_subnet.id
  #private_dns_zone_id = azurerm_private_dns_zone.dns.id
  public_network_access_enabled = false

  # prevent the possibility of accidental data loss
  # lifecycle {
  #   prevent_destroy = true
  # }
}

# Define a PostgreSQL Flexible Server Database
resource "azurerm_postgresql_flexible_server_database" "postgres_database" {
  name                = var.database_name
  server_id           = azurerm_postgresql_flexible_server.postgres_server.id

  #prevent the possibility of accidental data loss
  # lifecycle {
  #   prevent_destroy = true
  # }
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
    name = "dns_idk_name"
    private_dns_zone_ids = [ azurerm_private_dns_zone.dns.id ]
  }
}

resource "azurerm_private_dns_a_record" "postgres_dns_record" {
  name                = "database"
  zone_name           = azurerm_private_dns_zone.dns.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.database_private_endpoint.private_service_connection[0].private_ip_address]
}