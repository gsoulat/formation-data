output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}


output "primary_blob_endpoint" {
  value = azurerm_storage_account.sa.primary_blob_endpoint
}
