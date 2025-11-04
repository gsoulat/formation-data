variable "subscription_id" {
  description = "L'ID de la subscription Azure"
  type        = string
  default     = "" # TODO: Mettre votre subscription_id
}


variable "location" {
  description = "La localisation Azure"
  type        = string
  default     = "francecentral"
}


variable "rg_names" {
  description = "Les noms des resource groups"
  default = {
    dev     = "rg1dev"
    staging = "rg1staging"
    prod    = "rg1prod"
    default = "rg1"
  }
}
