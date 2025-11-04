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

# Resource Group principal
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Créer plusieurs storage accounts avec for_each
resource "azurerm_storage_account" "storage" {
  for_each = var.storage_configs

  name                     = "${each.key}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = each.value.tier
  account_replication_type = each.value.replication

  tags = {
    environment = each.value.environment
    tier        = each.value.tier
  }
}

# Locals avec expressions FOR pour transformer les données
locals {
  # 1. FOR pour créer une liste à partir d'une map
  storage_names = [
    for key, config in var.storage_configs : "${key}${random_string.suffix.result}"
  ]

  # 2. FOR pour créer une map à partir d'une map (transformation)
  storage_endpoints = {
    for key, storage in azurerm_storage_account.storage :
    key => storage.primary_blob_endpoint
  }

  # 3. FOR avec condition (filtrage)
  premium_storage = {
    for key, config in var.storage_configs :
    key => config if config.tier == "Premium"
  }

  # 4. FOR pour créer des tags à partir d'une liste
  resource_tags = {
    for idx, env in var.environments :
    "environment_${idx}" => env
  }

  # 5. FOR avec plusieurs conditions
  prod_standard_storage = [
    for key, config in var.storage_configs :
    key if config.tier == "Standard" && config.environment == "prod"
  ]

  # 6. FOR imbriqué (liste de listes aplatie)
  all_container_combinations = flatten([
    for storage_key, storage_config in var.storage_configs : [
      for container in var.container_names : {
        storage   = storage_key
        container = container
        tier      = storage_config.tier
      }
    ]
  ])
}
