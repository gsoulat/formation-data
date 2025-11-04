output "existing_rg_location" {
  description = "La localisation du resource group existant"
  value       = data.azurerm_resource_group.existing_rg.location
}

output "existing_rg_id" {
  description = "L'ID du resource group existant"
  value       = data.azurerm_resource_group.existing_rg.id
}

output "subscription_display_name" {
  description = "Le nom d'affichage de la subscription"
  value       = data.azurerm_subscription.current.display_name
}

output "subscription_id" {
  description = "L'ID de la subscription"
  value       = data.azurerm_subscription.current.subscription_id
}

output "storage_account_id" {
  description = "L'ID du storage account créé"
  value       = azurerm_storage_account.storage.id
}

output "storage_account_primary_endpoint" {
  description = "L'endpoint principal du storage account"
  value       = azurerm_storage_account.storage.primary_blob_endpoint
}
