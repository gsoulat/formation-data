output "storage_names" {
  description = "Liste des noms de storage accounts (FOR sur map -> list)"
  value       = local.storage_names
}

output "storage_endpoints" {
  description = "Map des endpoints (FOR transformation)"
  value       = local.storage_endpoints
}

output "premium_storage" {
  description = "Filtrage : Seulement les storage Premium (FOR avec if)"
  value       = local.premium_storage
}

output "resource_tags" {
  description = "Tags créés à partir d'une liste (FOR list -> map)"
  value       = local.resource_tags
}

output "prod_standard_storage" {
  description = "Storage Standard ET prod (FOR avec multiple conditions)"
  value       = local.prod_standard_storage
}

output "all_container_combinations" {
  description = "Toutes les combinaisons storage/container (FOR imbriqué + flatten)"
  value       = local.all_container_combinations
}

output "storage_account_ids" {
  description = "IDs de tous les storage accounts"
  value = {
    for key, storage in azurerm_storage_account.storage :
    key => storage.id
  }
}

output "storage_summary" {
  description = "Résumé de chaque storage account"
  value = {
    for key, storage in azurerm_storage_account.storage :
    key => {
      name        = storage.name
      tier        = storage.account_tier
      replication = storage.account_replication_type
      endpoint    = storage.primary_blob_endpoint
    }
  }
}
