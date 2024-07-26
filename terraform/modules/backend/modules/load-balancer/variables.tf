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

variable "backend_subnet_id" {
  type = string
  description = "Id of the subnet containing backend virtual machines"
}

variable "frontend_subnet_id" {
  type = string
  description = "Id of the subnet in which the load balancer acces will be exposed"
}

variable "frontend_ip" {
  type = string
  description = "Ip by which the load balancer will be accessible"
}