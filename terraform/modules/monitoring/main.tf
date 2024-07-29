resource "azurerm_public_ip" "monitoring_public_ip" {
  name                = "${var.resource_group_name}_monitoring_public_ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  domain_name_label   = "group1-monitoring"
  sku = "Standard"
}

resource "azurerm_network_interface" "monitoring_nic" {
  count = 1
  name                = "${var.resource_group_name}_monitoring_nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.monitoring_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "22.0.10.10"
    public_ip_address_id          = azurerm_public_ip.monitoring_public_ip.id
  }
}

# Create security group for frontend
resource "azurerm_network_security_group" "monitoring_sg" {
  name                = "${var.resource_group_name}_monitoring_sg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "frontend-loki-rule"
    priority                   = 1200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3100"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "frontend-grafana-rule"
    priority                   = 1300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate the Network Security Group to the subnet
resource "azurerm_subnet_network_security_group_association" "my_monitoring_sg_association" {
  subnet_id                 = var.monitoring_subnet_id
  network_security_group_id = azurerm_network_security_group.monitoring_sg.id
}

#Create vm
resource "azurerm_linux_virtual_machine" "vm" {
  count = var.vm_count
  name                = "${var.resource_group_name}-vm-monitoring"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_F1"
  admin_username      = var.vm_username
  
  network_interface_ids = [
    azurerm_network_interface.monitoring_nic[0].id,
  ]

  admin_ssh_key {
    username   = var.vm_username
    public_key = file("${var.public_key_location}/monitoring_key.pub")
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

  tags = {
    "idemia:cpe:auto:poweroffrange" = "19:00!"
  }

  custom_data = base64encode(templatefile(var.cloud_init_location, {
        DOCKER_USERNAME = var.docker_username,
        DOCKER_PASSWORD = var.docker_password,
        LOKI_CONFIG     = base64encode(templatefile("${path.module}/loki-config.yaml", {
          storage_account_name = var.storage_account_name,
          storage_account_key  = var.storage_account_key,
          container_name       = var.container_name
        })),
        # LOKI_CONFIG = base64encode(file("${path.module}/loki-config.yaml")),
        GRAFANA_USERNAME = var.grafana_username,
        GRAFANA_PASSWORD = var.grafana_password,
     }))
}
