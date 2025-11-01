# Azure Cosmos DB NoSQL - Main configuration
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

# Azure Cosmos DB NoSQL resources will be defined here

resource "azurerm_cosmosdb_account" "nosql" {
  name                = "${var.project_name}-cosmosnosql"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  enable_automatic_failover = false

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = data.azurerm_resource_group.main.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_database" "main" {
  name                = "nosql-database"
  resource_group_name = data.azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.nosql.name
}
