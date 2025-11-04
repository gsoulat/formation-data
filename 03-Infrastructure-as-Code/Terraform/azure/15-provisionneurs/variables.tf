variable "subscription_id" {
  description = "L'ID de la subscription Azure"
  type        = string
  default     = "" # TODO: Mettre votre subscription_id
}

variable "resource_group_name" {
  description = "Le nom du resource group"
  type        = string
  default     = "rg-provisioner-example"
}

variable "location" {
  description = "La localisation Azure"
  type        = string
  default     = "westeurope"
}

variable "storage_account_name" {
  description = "Le nom du storage account (doit être unique)"
  type        = string
  default     = "storageprov15" # Doit être unique globalement
}
