resource "azurerm_network_security_group" "nsg1" {
  name                = "web-nsg-${local.common_prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.terraformlearning.name
  tags = local.common_tags
}