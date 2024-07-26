variable "resource_group_name" {
  type = string
  description = "Name of the resource group for the module"
  default = "group1"
}

variable "location" {
  type = string
  description = "Location of resources inside the module"
  default = "Poland Central"
}

variable "vnet_name" {
  type = string
  description = "Name of the virtual network where the backend will be placed"
}

variable "bastion_subnet_adress_prefixes" {
  type = list(string)
  description = "Adress prefixes used for bastion subnet"
  default = ["22.0.9.0/24"]
}