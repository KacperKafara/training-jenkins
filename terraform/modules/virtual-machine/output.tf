output "load_balancer_nic" {
  value = azurerm_network_interface.load_balancer_nic
  description = "List of nic connecting vm's with load balancer subnet"
}

# output "database_nic" {
#   value = azurerm_network_interface.database_nic
#   description = "List of nic connecting vm's with database connection subnet"
# }