
output "resource_group_name" {
  description = "Le nom du resource group créé"
  value       = azurerm_resource_group.rg.name
}

output "storage_account_name" {
  description = "Le nom du storage account créé"
  value       = azurerm_storage_account.storage.name
}


output "location" {
  description = "La localisation des ressources"
  value       = azurerm_resource_group.rg.location
}
