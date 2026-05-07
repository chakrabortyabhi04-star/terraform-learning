resource "azurerm_resource_group" "terraformlearning" {
  name     = "rg-terraform-learning"
  location = "West Europe"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet_learning"
  location            = azurerm_resource_group.terraformlearning.location
  resource_group_name = azurerm_resource_group.terraformlearning.name
  address_space       = ["10.0.0.0/16"]
}