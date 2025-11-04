output "storage_account_tier" {
  value = azurerm_storage_account.sa.account_tier
}

output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}
