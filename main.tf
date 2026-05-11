resource "azurerm_resource_group" "terraformlearning" {
  name     = var.resource_group_name
  location = var.location
  tags = local.common_tags
  
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags = local.common_tags
  
}