variable "resource_group_name" {
  type    = string
  default = "rg-soulat-dev" # Pas une bonne pratique
}

variable "storage_account_name" {
  type    = string
  default = "gsobucket" # Pas une bonne pratique
}

variable "container_name" {
  type    = string
  default = "folder" # Pas une bonne pratique
}

variable "subscription_id" {
  type    = string
  default = "029b3537-0f24-400b-b624-6058a145efe1" # Pas une bonne pratique
}

variable "location" {
  type    = string
  default = "francecentral" # Pas dérangeant
}
