resource "azurerm_resource_group" "terraformlearning" {
  name     = "rg-${local.common_prefix}"
  location = var.location
  tags = local.common_tags
  
}



module "module_practice" {
  source = "./modules/networking"

  location            = var.location
  resource_group_name = var.resource_group_name
  environment         = var.environment
   address_space      = var.vnet_address_space
}

module "vnet" {
  source  = "Azure/vnet/azurerm"
  version = "5.0.1"

  resource_group_name =var.resource_group_name
  vnet_location       = var.location
}
