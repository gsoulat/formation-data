# Azure Service Bus - Main configuration
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

# Azure Service Bus resources will be defined here

resource "azurerm_servicebus_namespace" "main" {
  name                = "${var.project_name}-servicebus"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "Standard"

  tags = {
    Environment = var.environment
    Service     = "ServiceBus"
  }
}

resource "azurerm_servicebus_topic" "main" {
  name         = "main-topic"
  namespace_id = azurerm_servicebus_namespace.main.id
}

resource "azurerm_servicebus_subscription" "main" {
  name     = "main-subscription"
  topic_id = azurerm_servicebus_topic.main.id
}
