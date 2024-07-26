resource "azurerm_network_interface" "monitoring_nic" {
  count = 1
  name                = "${var.resource_group_name}_monitoring_nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.monitoring_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address = "22.0.10.10"
  }
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
    azurerm_network_interface.monitoring_nic[0].id
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
        LOKI_CONFIG     = templatefile("${path.module}/loki-config.tpl", {
          storage_account_name = var.storage_account_name,
          storage_account_key  = var.storage_account_key,
          container_name       = var.container_name
        }),
        GRAFANA_USERNAME = var.grafana_username,
        GRAFANA_PASSWORD = var.grafana_password,
     }))
}
