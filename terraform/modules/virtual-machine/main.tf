resource "azurerm_network_interface" "load_balancer_nic" {
  count = var.vm_count
  name                = "${var.resource_group_name}_lb_nic_${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.load_balancer_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# resource "azurerm_network_interface" "database_nic" {
#   count = var.vm_count
#   name                = "${var.resource_group_name}_db_con_nic_${count.index}"
#   location            = var.location
#   resource_group_name = var.resource_group_name

#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = var.database_subnet_id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

#Create vm
resource "azurerm_linux_virtual_machine" "vm" {
  count = var.vm_count
  name                = "${var.resource_group_name}-vm-${count.index}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_F1"
  admin_username      = var.vm_username
  
  network_interface_ids = [
    azurerm_network_interface.load_balancer_nic[count.index].id,
    # azurerm_network_interface.database_nic[count.index].id
  ]

  admin_ssh_key {
    username   = var.vm_username
    public_key = file("${var.public_key_location}/key_vm${count.index}.pub")
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
       DOCKER_PASSWORD = var.docker_password
     }))
}