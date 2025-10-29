
# Déclaré un provider
provider "azurerm" {
  features {

  }
  subscription_id = "" # TODO : Mettre votre subscription_id
}

# Dans le terminal tapez terraform init

resource "azurerm_resource_group" "rg" {
  name     = "rg1"
  location = "westeurope"
}

