

resource "azurerm_public_ip" "Publicip" {
  name                = "publicip-${local.common_prefix}"
  resource_group_name = azurerm_resource_group.terraformlearning.name
  location            = var.location
  allocation_method   = "Static"

  tags = local.common_tags
}


resource "azurerm_network_interface" "nic" {
  name                = "nic-${local.common_prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.terraformlearning.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.Publicip.id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-${local.common_prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.terraformlearning.name
  size                = "Standard_B1s"
  network_interface_ids = [azurerm_network_interface.nic.id]
  admin_username      = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}