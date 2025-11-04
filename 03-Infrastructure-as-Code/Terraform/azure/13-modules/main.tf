terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.50.0"
    }
  }
}

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

module "storage" {
  source               = "./module/storage"
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_name = "${var.storage_account_name}${random_string.suffix.result}"
  location             = var.location
  container_name       = "${var.container_name}${random_string.suffix.result}"
}

module "app_service" {
  source              = "./module/app_service"
  app_service_name    = "${var.app_service_name}${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
}
