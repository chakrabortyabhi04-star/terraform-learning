output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "Azure Virtual network address"
}

output "rg_id" {
  value       = azurerm_resource_group.terraformlearning.id
  description = "Azure resource group name"
}

output "module_vnet_name" {
  value = module.module_practice.vnet_name
  description = "Azure resource group name"
}