variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
  default     = "rg-soulat-dev" # Pas une bonne pratique
}

variable "storage_account_name" {
  type        = string
  description = "Name of the storage account"
  default     = "gsobucket" # Pas une bonne pratique
}

variable "container_name" {
  type        = string
  description = "Name of the container"
  default     = "folder" # Pas une bonne pratique
}

variable "subscription_id" {
  type        = string
  description = "Subscription ID"
  default     = "029b3537-0f24-400b-b624-6058a145efe1" # Pas une bonne pratique
}

variable "location" {
  type        = string
  description = "Location of the resource group"
  default     = "francecentral" # Pas dérangeant
}

variable "number" {
  type        = number
  description = "Number of the resource group"
  default     = 1
}

variable "bool" {
  type        = bool
  description = "Boolean of the resource group"
  default     = true
}

variable "list" {
  type        = list(string)
  description = "List of the resource group"
  default     = ["folder1", "folder2", "folder3"]
}

variable "map" {
  type        = map(string)
  description = "Map of the resource group"
  default     = { "folder1" = "folder1", "folder2" = "folder2", "folder3" = "folder3" }
}

variable "set" {
  type        = set(string)
  description = "Set of the resource group"
  default     = ["folder1", "folder2", "folder3"]
}

variable "triangle" {
  type = object({
    s_one       = number
    s_two       = number
    s_three     = number
    description = string
  })
  default = { "s_one" = 1, "s_two" = 2, "s_three" = 3, "description" = "Triangle" }
}

variable "tuple" {
  type        = tuple([string, number, bool])
  description = "Tuple of the resource group"
  default     = ["folder1", 1, true]
}

variable "any" {
  type        = any
  description = "Any of the resource group"
  default     = "folder1"
}
