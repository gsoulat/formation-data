# Outputs for Azure Virtual Network

# Add your outputs here

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "subnet_id" {
  description = "ID of the internal subnet"
  value       = azurerm_subnet.internal.id
}
