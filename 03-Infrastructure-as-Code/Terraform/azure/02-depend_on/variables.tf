variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "resource_group_name" {
  type        = string
  description = "Nom du resource group"
  default     = "rg-depend-on-example"
}

variable "location" {
  type        = string
  description = "Localisation Azure"
  default     = "westeurope"
}

variable "storage_account_name" {
  type        = string
  description = "Nom du storage account (doit être unique globalement)"
  default     = "stdependon123"

  validation {
    condition     = length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24
    error_message = "Le nom du storage account doit faire entre 3 et 24 caractères."
  }
}

variable "container_name" {
  type        = string
  description = "Nom du container de stockage"
  default     = "data"
}
