resource "azurerm_storage_account" "sa" {
  name                     = "mystorageaccount${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Ou "GRS", "RAGRS", "ZRS"
}


resource "azurerm_storage_container" "container" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"

  count = local.deployContainer ? 1 : 0
}
