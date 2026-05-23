resource "azurerm_resource_group" "terraformlearning" {
  name     = "rg-${local.common_prefix}"
  location = var.location
  tags = local.common_tags
  
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.common_prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.terraformlearning.name
  address_space       = var.vnet_address_space
  tags = local.common_tags
  
  
}

module "module_practice" {
  source = "./modules/networking"

  location            = var.location
  resource_group_name = var.resource_group_name
  environment         = var.environment
}

