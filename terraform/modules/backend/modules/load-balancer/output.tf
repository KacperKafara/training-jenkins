output "backend_address_pool_id" {
  value = azurerm_lb_backend_address_pool.backend_pool.id
  description = "Id of the backend pool associated with the load balancer"
}