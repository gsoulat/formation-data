# Azure Synapse Analytics - Main configuration
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

# Azure Synapse Analytics resources will be defined here

resource "azurerm_storage_account" "synapse" {
  name                     = "${var.project_name}synapse${var.environment}"
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = data.azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}

resource "azurerm_storage_data_lake_gen2_filesystem" "synapse" {
  name               = "synapse-filesystem"
  storage_account_id = azurerm_storage_account.synapse.id
}

resource "azurerm_synapse_workspace" "main" {
  name                                 = "${var.project_name}-synapse"
  resource_group_name                  = data.azurerm_resource_group.main.name
  location                             = data.azurerm_resource_group.main.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse.id
  sql_administrator_login              = var.synapse_admin_login
  sql_administrator_login_password     = var.synapse_admin_password

  identity {
    type = "SystemAssigned"
  }
}
