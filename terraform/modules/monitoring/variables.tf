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

variable "monitoring_subnet_id" {
    type = string
    description = "Id of the subnet connecting monitoring with the rest of the infrastructure"
}

variable "vm_count" {
  type = number
  description = "Numbet of virtual machines to create"
  default = 1
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
}

variable "grafana_username" {
  description = "grafana username"
  type = string
}

variable "grafana_password" {
  description = "grafana password"
  type = string
}

variable "public_key_location" {
  type = string
  description = "Directory with public keys for vm's. Keys must be named key_vm{number_of_the_vm}.pub"
  #default = "${path.root}/keys"
}

variable "cloud_init_location" {
  type = string
  description = "Location of the cloud init file"
  # default = "${path.root}/cloud-init.yml"
}

variable "storage_account_name" {
  type = string
  description = "Name of the storage account"
}

variable "storage_account_key" {
  type = string
  description = "Key to the storage account"
}

variable "container_name" {
  type = string
  description = "Name of the container in the storage account"
}
