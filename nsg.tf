resource "azurerm_network_security_group" "nsg1" {
  name                = "web-nsg-${local.common_prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.terraformlearning.name
  tags = local.common_tags
}

resource "azurerm_network_security_rule" "nsr" {
  name                        = "nsr-${local.common_prefix}"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.terraformlearning.name
  network_security_group_name = azurerm_network_security_group.nsg1.name
}


resource "azurerm_subnet_network_security_group_association" "nsg-association" {
  subnet_id                 = azurerm_subnet.subnet_1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}