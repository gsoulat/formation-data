terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.50.0"
    }
  }
  # backend "local" {
  #   path = "./states/terraform.tfstate"
  # }
  backend "azurerm" {
    resource_group_name  = "RG-STATES"
    storage_account_name = "remotestates"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

# Déclaré un provider
provider "azurerm" {
  skip_provider_registration = true
  features {}
  subscription_id = var.subscription_id
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}


resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}


resource "azurerm_storage_account" "sa" {
  name                     = "${var.storage_account_name}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "sc" {
  name               = var.container_name
  storage_account_id = azurerm_storage_account.sa.id
}


