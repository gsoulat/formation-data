# Azure DevOps - Main configuration
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

# Azure DevOps resources will be defined here

# Note: Azure DevOps is typically managed outside of Terraform
# This module provides basic automation resources

resource "azurerm_automation_account" "main" {
  name                = "${var.project_name}-automation"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku_name            = "Basic"

  tags = {
    Environment = var.environment
    Service     = "Automation"
  }
}
