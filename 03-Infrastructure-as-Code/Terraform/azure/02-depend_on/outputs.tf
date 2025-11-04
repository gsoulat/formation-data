output "resource_group_id" {
  description = "ID du resource group"
  value       = azurerm_resource_group.rg.id
}

output "storage_account_name" {
  description = "Nom du storage account créé"
  value       = azurerm_storage_account.storage.name
}

output "storage_account_id" {
  description = "ID du storage account"
  value       = azurerm_storage_account.storage.id
}

output "container_name" {
  description = "Nom du container créé"
  value       = azurerm_storage_container.container.name
}

output "role_assignment_id" {
  description = "ID du role assignment créé"
  value       = azurerm_role_assignment.storage_contributor.id
}

output "blob_url" {
  description = "URL du blob créé"
  value       = azurerm_storage_blob.example_blob.url
}

output "deployment_order" {
  description = "Ordre de création des ressources (démonstration)"
  value = {
    "1_resource_group"  = azurerm_resource_group.rg.name
    "2_storage_account" = azurerm_storage_account.storage.name
    "3_container"       = azurerm_storage_container.container.name
    "4_role_assignment" = "Created with depends_on"
    "5_post_deployment" = "Script executed after all resources"
    "6_blob"            = azurerm_storage_blob.example_blob.name
  }
}

output "dependency_graph" {
  description = "Graphe des dépendances (pour illustration)"
  value       = <<-EOT
    Resource Group
         ↓ (implicit)
    Storage Account
         ↓ (implicit)
    Storage Container
         ↓ (explicit depends_on)
    Role Assignment
         ↓ (explicit depends_on)
    Post Deployment Script
         ↓ (explicit depends_on)
    Storage Blob
  EOT
}
