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

variable "database_login" {
  description = "Login of the admin account to the database"
  type = string
  default = "username"
}

variable "database_password" {
  description = "Password of the admin account to the database"
  type = string
  default = "password"
}

variable "database_name" {
  description = "Name of the database"
  type = string
  default = "parkingDb"
}

# variable "vnet_adress_space"{
#     type = tuple([ string ])
#     description = "Prefixes for the database subnet"
#     #default = ["22.0.3.0/24"]
# }

variable "vnet"{
    type = object({
      name =  string
      id = string
    })
    description = "vnet"
    #default = ["22.0.3.0/24"]
}

variable "db_server_subnet_adress_prefixes"{
    type = tuple([ string ])
    description = "Prefixes for the database subnet"
    #default = ["22.0.4.0/24"]
}

variable "db_connection_subnet_adress_prefixes"{
    type = tuple([ string ])
    description = "Prefixes for the database subnet"
    #default = ["22.0.3.0/24"]
}