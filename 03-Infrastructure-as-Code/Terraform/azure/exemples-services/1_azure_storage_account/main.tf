# Azure Storage Account - Main configuration
# Generated on Jeu  5 jui 2025 14:14:42 CEST

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

# Reference to shared resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Azure Storage Account resources will be defined here

resource "azurerm_storage_account" "main" {
  name                     = "${var.project_name}storage${var.environment}"
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = data.azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version = "TLS1_2"

  tags = {
    Environment = var.environment
    Service     = "Storage"
  }
}

resource "azurerm_storage_container" "main" {
  name                  = "main-container"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}
