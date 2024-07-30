#Create public ip for frontend
resource "azurerm_public_ip" "frontend_public_ip" {
  name                = "${var.resource_group_name}_frontend_public_ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  domain_name_label   = "group1-parkanizer"
  sku = "Standard"
}

#Create nic for vm3
resource "azurerm_network_interface" "frontend_nic1" {
  name                = "${var.resource_group_name}_frontend_nic1"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.fronend_subnet_id
    public_ip_address_id          = azurerm_public_ip.frontend_public_ip.id
  }
}

# Create security group for frontend
resource "azurerm_network_security_group" "frontend_sg" {
  name                = "frontend-sg"
  location            = var.location
  resource_group_name = var.resource_group_name

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
  subnet_id                 = var.fronend_subnet_id
  network_security_group_id = azurerm_network_security_group.frontend_sg.id
}

#Create vm 3 (frontend)
resource "azurerm_linux_virtual_machine" "frontend_vm" {
  name                = "${var.resource_group_name}-vm-frontend"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_F1"
  admin_username      = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.frontend_nic1.id
  ]

  admin_ssh_key {
    username   = "adminuser"
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
       DOCKER_USERNAME = var.docker_username,
       DOCKER_PASSWORD = var.docker_password,
       PROMTAIL_CONFIG = base64encode(file("${path.module}/promtail-config.yml"))
     }))
}