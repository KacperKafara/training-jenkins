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

variable "load_balancer_subnet_id" {
    type = string
    description = "Id of the subnet connecting load balancer and the vm's"
}

# variable "database_subnet_id" {
#     type = string
#     description = "Id of the subnet connecting the vm's to database"
# }

variable "vm_count" {
  type = number
  description = "Numbet of virtual machines to create"
  default = 2
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