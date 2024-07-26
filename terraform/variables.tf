variable "DOCKER_USERNAME" {
  description = "acr username"
  type = string
  default = "username"
}

variable "DOCKER_PASSWORD" {
  description = "acr password"
  type = string
  default = "password"
}

variable "GRAFANA_USERNAME" {
  description = "grafana username"
  type = string
  default = "username"
}

variable "GRAFANA_PASSWORD" {
  description = "grafana password"
  type = string
  default = "password"
}

variable "DATABASE_LOGIN" {
  description = "postgres admin login"
  type = string
  default = "username"
}

variable "DATABASE_PASSWORD" {
  description = "postgres admin password"
  type = string
  default = "password"
}

variable "DATABASE_NAME" {
  description = "postgres database name"
  type = string
  default = "parkingDb"
}