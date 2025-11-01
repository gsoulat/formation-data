# Variables for Azure Synapse Analytics

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "azure-terraform-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "azure-project"
}

variable "synapse_admin_login" {
  description = "Synapse administrator login"
  type        = string
  default     = "synapseadmin"
}

variable "synapse_admin_password" {
  description = "Synapse administrator password"
  type        = string
  sensitive   = true
}
