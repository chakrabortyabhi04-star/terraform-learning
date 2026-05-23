output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "azurerm_subnet" {
  value = azurerm_subnet.web.id
}

output "azurerm_network_security_group" {
  value = azurerm_network_security_group.nsg1.id
}