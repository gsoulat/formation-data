variable "resource_group_name" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "container_name" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "westeurope" # Pas dérangeant
}

variable "resource_group_names" {
  type    = list(string)
  default = ["dev", "uat", "prod"]
}

