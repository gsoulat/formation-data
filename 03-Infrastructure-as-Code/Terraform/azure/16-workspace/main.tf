terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.50.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}


# Resource Group avec nom basé sur le workspace
resource "azurerm_resource_group" "rg" {
  name     = lookup(var.rg_names, terraform.workspace, var.rg_names.default)
  location = var.location

  tags = {
    managed_by = "terraform"
    workspace  = terraform.workspace
  }
}

# Storage Account avec configuration différente par environnement
resource "azurerm_storage_account" "storage" {
  name                     = "st${terraform.workspace}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"


  tags = {
    managed_by = "terraform"
    workspace  = terraform.workspace
  }
}

# Génération d'un suffixe aléatoire pour garantir l'unicité
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}


