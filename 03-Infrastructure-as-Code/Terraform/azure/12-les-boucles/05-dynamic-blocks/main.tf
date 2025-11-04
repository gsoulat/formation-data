terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.50.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Network Security Group avec dynamic blocks pour les règles
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Dynamic block pour créer plusieurs règles de sécurité
  dynamic "security_rule" {
    for_each = var.security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }

  tags = {
    environment = "demo-dynamic-blocks"
  }
}

# Storage Account avec dynamic blocks pour les règles réseau
resource "azurerm_storage_account" "storage" {
  name                     = "st${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Dynamic block pour les règles réseau (optionnel)
  dynamic "network_rules" {
    for_each = var.enable_network_rules ? [1] : []
    content {
      default_action             = "Deny"
      bypass                     = ["AzureServices"]
      ip_rules                   = var.allowed_ips
      virtual_network_subnet_ids = []
    }
  }

  # Dynamic block pour les blobs containers
  dynamic "blob_properties" {
    for_each = var.enable_blob_versioning ? [1] : []
    content {
      versioning_enabled = true

      dynamic "delete_retention_policy" {
        for_each = var.blob_retention_days > 0 ? [1] : []
        content {
          days = var.blob_retention_days
        }
      }
    }
  }

  tags = {
    environment = "demo-dynamic-blocks"
  }
}

# App Service avec dynamic blocks pour les configurations
resource "azurerm_service_plan" "asp" {
  name                = "asp-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "app" {
  name                = "app-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.asp.location
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    # Dynamic block pour les app settings
    dynamic "application_stack" {
      for_each = var.app_runtime != null ? [var.app_runtime] : []
      content {
        node_version = application_stack.value.node_version
      }
    }

    # Dynamic block pour CORS
    dynamic "cors" {
      for_each = length(var.cors_allowed_origins) > 0 ? [1] : []
      content {
        allowed_origins     = var.cors_allowed_origins
        support_credentials = var.cors_support_credentials
      }
    }
  }

  # Dynamic block pour les app_settings
  app_settings = merge(
    var.default_app_settings,
    var.custom_app_settings
  )

  tags = {
    environment = "demo-dynamic-blocks"
  }
}

# Exemple avec dynamic imbriqué - Key Vault
resource "azurerm_key_vault" "kv" {
  name                       = "kv-${random_string.suffix.result}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7

  # Dynamic block pour les access policies
  dynamic "access_policy" {
    for_each = var.key_vault_access_policies
    content {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = access_policy.value.object_id

      key_permissions         = access_policy.value.key_permissions
      secret_permissions      = access_policy.value.secret_permissions
      certificate_permissions = access_policy.value.certificate_permissions
    }
  }

  # Dynamic block pour les network ACLs
  dynamic "network_acls" {
    for_each = var.enable_kv_network_rules ? [1] : []
    content {
      bypass         = "AzureServices"
      default_action = "Deny"
      ip_rules       = var.allowed_ips
    }
  }

  tags = {
    environment = "demo-dynamic-blocks"
  }
}

# Data source pour obtenir le client config
data "azurerm_client_config" "current" {}
