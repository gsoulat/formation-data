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
  subscription_id = "029b3537-0f24-400b-b624-6058a145efe1"
}

# Récupérer les informations du client Azure AD actuel
data "azurerm_client_config" "current" {}

# Générer un suffixe aléatoire
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-soulat" # Attention le nom doit être unique : donc mettre le votre
  location = "francecentral"
}




