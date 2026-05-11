output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "Azure Virtual network address"
}

output "rg_id" {
  value       = azurerm_resource_group.terraformlearning.id
  description = "Azure resource group name"
}