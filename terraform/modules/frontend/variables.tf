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

variable "fronend_subnet_id" {
  type = string
  description = "Id of the subnet connecting load balancer and frontend machine"
}

variable "docker_password" {
  type = string
  description = "Password to a docker registry"
}

variable "docker_username" {
  type = string
  description = "Usename to a docker registry"
}