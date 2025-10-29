terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.50.0"
    }
  }
}

# Déclaré un provider
provider "azurerm" {
  features {}
  subscription_id = "029b3537-0f24-400b-b624-6058a145efe1" #Attention mauvaise pratique
}

# Récupérer les informations du client Azure AD actuel
data "azurerm_client_config" "current" {}

# Générer un suffixe aléatoire
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Pour créer un ressource group (sorte panier)
resource "azurerm_resource_group" "rg" {
  name     = "rg-soulat"
  location = "francecentral"
}

# creer un S1 service plan
resource "azurerm_app_service_plan" "asp" {
  name                = "asp1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }
}

# pour créer un service
resource "azurerm_app_service" "as" {
  name                = "soulatapp${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.asp.id

  site_config {
    linux_fx_version = "DOCKER|nginx:latest"
  }
}


# Pour créer un service account
resource "azurerm_storage_account" "sa" {
  name                     = "gsobucket${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
