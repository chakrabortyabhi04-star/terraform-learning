resource "azurerm_subnet" "subnet_1" {
  name                 = "web-subnet-${local.common_prefix}"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.terraformlearning.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet_2" {
  name                 = "app-subnet-${local.common_prefix}"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.terraformlearning.name
  address_prefixes = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "subnet_3" {
  name                 = "database-subnet-${local.common_prefix}"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.terraformlearning.name
  address_prefixes = ["10.0.3.0/24"]
}