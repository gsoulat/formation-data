output "nsg_id" {
  description = "ID du Network Security Group"
  value       = azurerm_network_security_group.nsg.id
}

output "nsg_rules_count" {
  description = "Nombre de règles de sécurité créées"
  value       = length(var.security_rules)
}

output "storage_account_name" {
  description = "Nom du storage account"
  value       = azurerm_storage_account.storage.name
}

output "storage_network_rules_enabled" {
  description = "Indique si les règles réseau sont activées"
  value       = var.enable_network_rules
}

output "app_service_url" {
  description = "URL de l'App Service"
  value       = "https://${azurerm_linux_web_app.app.default_hostname}"
}

output "cors_enabled" {
  description = "Indique si CORS est activé"
  value       = length(var.cors_allowed_origins) > 0
}

output "key_vault_name" {
  description = "Nom du Key Vault"
  value       = azurerm_key_vault.kv.name
}

output "key_vault_uri" {
  description = "URI du Key Vault"
  value       = azurerm_key_vault.kv.vault_uri
}

output "key_vault_access_policies_count" {
  description = "Nombre d'access policies configurées"
  value       = length(var.key_vault_access_policies)
}

output "summary" {
  description = "Résumé de la configuration avec dynamic blocks"
  value = {
    nsg = {
      id          = azurerm_network_security_group.nsg.id
      rules_count = length(var.security_rules)
    }
    storage = {
      name                 = azurerm_storage_account.storage.name
      network_rules_enabled = var.enable_network_rules
      blob_versioning      = var.enable_blob_versioning
    }
    app_service = {
      url          = "https://${azurerm_linux_web_app.app.default_hostname}"
      cors_enabled = length(var.cors_allowed_origins) > 0
    }
    key_vault = {
      name               = azurerm_key_vault.kv.name
      uri                = azurerm_key_vault.kv.vault_uri
      policies_count     = length(var.key_vault_access_policies)
      network_rules_enabled = var.enable_kv_network_rules
    }
  }
}
