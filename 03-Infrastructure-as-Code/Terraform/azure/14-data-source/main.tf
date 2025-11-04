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

# Data source : récupère les informations d'un resource group existant
# Cela permet de référencer des ressources créées en dehors de Terraform
data "azurerm_resource_group" "existing_rg" {
  name = var.existing_resource_group_name
}

# Data source : récupère les informations de la subscription courante
data "azurerm_subscription" "current" {
  # Ce data source ne nécessite pas de paramètres
}

# Utilisation des informations du data source pour créer une nouvelle ressource
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = data.azurerm_resource_group.existing_rg.name
  location                 = data.azurerm_resource_group.existing_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "learning"
    created_by  = "terraform-data-source-example"
  }
}

# On peut aussi créer de nouvelles ressources en utilisant les data sources
resource "azurerm_storage_container" "container" {
  name                  = "example-container"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}
