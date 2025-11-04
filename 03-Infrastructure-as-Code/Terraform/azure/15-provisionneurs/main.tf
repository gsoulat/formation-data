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

# Création d'un resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  # local-exec : s'exécute sur la machine qui lance Terraform
  provisioner "local-exec" {
    command = "echo 'Resource Group ${self.name} créé dans ${self.location}' >> provisioner-log.txt"
  }

  # local-exec lors de la destruction
  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Resource Group détruit à $(date)' >> provisioner-log.txt"
  }
}

# Création d'un storage account
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "learning"
  }

  # Exemple de local-exec avec plusieurs commandes
  provisioner "local-exec" {
    command = <<-EOT
      echo "==================================" >> provisioner-log.txt
      echo "Storage Account créé" >> provisioner-log.txt
      echo "Nom: ${self.name}" >> provisioner-log.txt
      echo "Date: $(date)" >> provisioner-log.txt
      echo "==================================" >> provisioner-log.txt
    EOT
  }

  # Gestion des erreurs avec on_failure
  provisioner "local-exec" {
    command    = "echo 'Configuration du storage terminée'"
    on_failure = continue # Options: fail (default) ou continue
  }
}

# Création d'un conteneur avec null_resource
# null_resource est utile pour exécuter des provisioners sans créer de vraie ressource Azure
resource "null_resource" "exemple_script" {
  # Ce provisioner s'exécutera à chaque changement du timestamp
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "echo \"Exécution d'un script personnalisé à $(date)\" >> provisioner-log.txt"
  }

  provisioner "local-exec" {
    command     = "print('Hello from Python!')"
    interpreter = ["python3", "-c"]
  }

  # Dépend du storage account
  depends_on = [azurerm_storage_account.storage]
}
