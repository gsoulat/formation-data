# Variables for Azure Virtual Machine

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

variable "subnet_id" {
  description = "ID of the subnet for the VM"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
