variable "subscription_id" {
  description = "L'ID de la subscription Azure"
  type        = string
  default     = "" # TODO: Mettre votre subscription_id
}

variable "existing_resource_group_name" {
  description = "Le nom d'un resource group existant à récupérer"
  type        = string
  default     = "RG-STATES" # TODO: Mettre le nom d'un RG existant dans votre subscription
}

variable "storage_account_name" {
  description = "Le nom du storage account à créer (doit être unique)"
  type        = string
  default     = "storagedata14" # Doit être unique globalement
}
