variable "resource_group_name" {
  type = string
  description = "Name of the resource group for the vm's"
  default = "group1"
}

variable "location" {
  type = string
  description = "Location of resources inside the module"
  default = "Poland Central"
}

variable "docker_password" {
  type = string
  description = "Password to a docker registry"
}

variable "docker_username" {
  type = string
  description = "Password to a docker registry"
}

variable "vm_username" {
  type = string
  description = "Username of the user on the vm"
  default = "adminuser"
}

variable "vnet_name" {
  type = string
  description = "Name of the virtual network where the backend will be placed"
}

variable "frontend_subnet" {
  type = object({
    id = string
    address_prefixes = list(string)
  })
  description = "Subnet where the frontend will be exposed"
}

variable "frontend_ip" {
  type = string
  description = "Ip by which the load balancer will be accessed"
  default = "22.0.1.4"
}

variable "backend_subnet_prefixes" {
  type = string
  description = "Adress prefixes for backend subnet"
  default = "22.0.1.4"
}