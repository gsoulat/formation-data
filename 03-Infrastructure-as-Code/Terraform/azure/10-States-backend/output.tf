output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "app_service_name" {
  value = azurerm_app_service.as.name
}

output "app_service_url" {
  value = azurerm_app_service.as.default_site_hostname
}
