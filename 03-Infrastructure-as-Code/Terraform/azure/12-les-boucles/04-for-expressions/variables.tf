variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
  default     = "rg-for-expressions"
}

variable "location" {
  type        = string
  description = "Azure location"
  default     = "westeurope"
}

variable "storage_configs" {
  type = map(object({
    tier        = string
    replication = string
    environment = string
  }))
  description = "Map of storage account configurations"
  default = {
    storagedev = {
      tier        = "Standard"
      replication = "LRS"
      environment = "dev"
    }
    storagestaging = {
      tier        = "Standard"
      replication = "GRS"
      environment = "staging"
    }
    storageprod = {
      tier        = "Premium"
      replication = "ZRS"
      environment = "prod"
    }
  }
}

variable "environments" {
  type        = list(string)
  description = "List of environments"
  default     = ["dev", "staging", "prod"]
}

variable "container_names" {
  type        = list(string)
  description = "List of container names"
  default     = ["data", "logs", "backups"]
}
