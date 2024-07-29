variable "DOCKER_USERNAME" {
  description = "acr username"
  type = string
}

variable "DOCKER_PASSWORD" {
  description = "acr password"
  type = string
}

variable "GRAFANA_USERNAME" {
  description = "grafana username"
  type = string
}

variable "GRAFANA_PASSWORD" {
  description = "grafana password"
  type = string
}

variable "DATABASE_LOGIN" {
  description = "postgres admin login"
  type = string
}

variable "DATABASE_PASSWORD" {
  description = "postgres admin password"
  type = string
}

variable "DATABASE_NAME" {
  description = "postgres database name"
  type = string
}