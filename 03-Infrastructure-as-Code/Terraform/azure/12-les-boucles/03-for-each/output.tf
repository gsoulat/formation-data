output "resource_group_names" {
  value       = { for k, rg in azurerm_resource_group.rg : k => rg.name }
  description = "Map of all resource group names"
}

output "resource_group_ids" {
  value       = { for k, rg in azurerm_resource_group.rg : k => rg.id }
  description = "Map of all resource group IDs"
}
