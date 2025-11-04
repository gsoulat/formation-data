output "resource_group_id" {
  description = "L'ID du resource group créé"
  value       = azurerm_resource_group.rg.id
}

output "storage_account_name" {
  description = "Le nom du storage account créé"
  value       = azurerm_storage_account.storage.name
}

output "storage_account_endpoint" {
  description = "L'endpoint du storage account"
  value       = azurerm_storage_account.storage.primary_blob_endpoint
}

output "log_file_info" {
  description = "Information sur le fichier de log créé par les provisioners"
  value       = "Consultez le fichier provisioner-log.txt dans le répertoire courant"
}
