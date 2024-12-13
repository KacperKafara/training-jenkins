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

variable "vnet" {
  type = object({
    name = string
    id = string
  })
  description = "virtual network where the backend will be placed"
}