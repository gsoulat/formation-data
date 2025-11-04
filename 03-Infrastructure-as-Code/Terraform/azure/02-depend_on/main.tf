terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.50.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }

  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# ============================================
# DÉPENDANCES IMPLICITES (Automatiques)
# ============================================

# 1. Resource Group (créé en premier automatiquement)
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    example = "depend_on"
  }
}

# 2. Storage Account - Dépendance IMPLICITE via resource_group_name
# Terraform comprend automatiquement que le RG doit exister avant
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name # Dépendance implicite
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    example = "implicit-dependency"
  }
}

# 3. Storage Container - Dépendance IMPLICITE via storage_account_id
resource "azurerm_storage_container" "container" {
  name               = var.container_name
  storage_account_id = azurerm_storage_account.storage.id # Dépendance implicite
}

# ============================================
# DÉPENDANCES EXPLICITES avec depends_on
# ============================================

# 4. Role Assignment - Besoin de DEPENDS_ON explicite
# Car aucune référence directe n'est utilisée dans les attributs
data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "storage_contributor" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id

  # Sans depends_on, cette ressource pourrait être créée avant que le Storage Account
  # soit complètement prêt, causant des erreurs intermittentes
  depends_on = [
    azurerm_storage_account.storage
  ]
}

# 5. Exemple avec plusieurs dépendances
# Un script qui nécessite que TOUTES les ressources soient créées
resource "null_resource" "post_deployment" {
  # Cette ressource attend que TOUT soit créé
  depends_on = [
    azurerm_resource_group.rg,
    azurerm_storage_account.storage,
    azurerm_storage_container.container,
    azurerm_role_assignment.storage_contributor
  ]

  provisioner "local-exec" {
    command = "echo 'Toutes les ressources sont créées ! Storage: ${azurerm_storage_account.storage.name}' > deployment-complete.txt"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Début de la destruction des ressources' >> deployment-complete.txt"
  }
}

