data "azurerm_resource_group" "existing_rg" {
  name = "rg-dev-terraform-learning"
}

data "azurerm_virtual_network" "existing_vnet" {
  name                = "vnet-dev-terraform-learning"
  resource_group_name = "rg-dev-terraform-learning"
}   

output "vnet_address_space" {
  value = data.azurerm_virtual_network.existing_vnet.address_space
}