variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
  default     = "rg-dynamic-blocks"
}

variable "location" {
  type        = string
  description = "Azure location"
  default     = "westeurope"
}

# Variables pour NSG
variable "security_rules" {
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  description = "Liste des règles de sécurité NSG"
  default = [
    {
      name                       = "allow-ssh"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "allow-https"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "allow-http"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
}

# Variables pour Storage Account
variable "enable_network_rules" {
  type        = bool
  description = "Activer les règles réseau sur le storage"
  default     = false
}

variable "allowed_ips" {
  type        = list(string)
  description = "Liste des IPs autorisées"
  default     = []
}

variable "enable_blob_versioning" {
  type        = bool
  description = "Activer le versioning des blobs"
  default     = true
}

variable "blob_retention_days" {
  type        = number
  description = "Nombre de jours de rétention des blobs supprimés"
  default     = 7
}

# Variables pour App Service
variable "app_runtime" {
  type = object({
    node_version = string
  })
  description = "Runtime de l'application"
  default = {
    node_version = "18-lts"
  }
}

variable "cors_allowed_origins" {
  type        = list(string)
  description = "Origines autorisées pour CORS"
  default     = []
}

variable "cors_support_credentials" {
  type        = bool
  description = "Support des credentials pour CORS"
  default     = false
}

variable "default_app_settings" {
  type        = map(string)
  description = "App settings par défaut"
  default = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "18-lts"
    "ENVIRONMENT"                  = "demo"
  }
}

variable "custom_app_settings" {
  type        = map(string)
  description = "App settings personnalisés"
  default     = {}
}

# Variables pour Key Vault
variable "key_vault_access_policies" {
  type = list(object({
    object_id               = string
    key_permissions         = list(string)
    secret_permissions      = list(string)
    certificate_permissions = list(string)
  }))
  description = "Liste des access policies pour Key Vault"
  default     = []
}

variable "enable_kv_network_rules" {
  type        = bool
  description = "Activer les règles réseau sur Key Vault"
  default     = false
}
