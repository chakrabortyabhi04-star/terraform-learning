resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
}

resource "azurerm_subnet" "web" {
  name                 = "subnet-web-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg1" {
  name                = "nsg-web-${var.environment}"
  location            = var.location
  resource_group_name =  var.resource_group_name


  dynamic "security_rule" {
  for_each = var.security_rules
  content {
    name                         = security_rule.value.name
    priority                     = security_rule.value.priority
    direction                    = security_rule.value.direction
    access                       = security_rule.value.access
    protocol                     = security_rule.value.protocol
    source_port_range            = security_rule.value.source_port_range
    destination_port_range       = security_rule.value.destination_port_range
    source_address_prefix        = security_rule.value.source_address_prefix
    destination_address_prefix   = security_rule.value.destination_address_prefix
  }
}
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}