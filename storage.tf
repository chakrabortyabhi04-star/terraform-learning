resource "azurerm_storage_account" "azure-storage1" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.terraformlearning.name
  location                 = azurerm_resource_group.terraformlearning.location
  account_tier             = "Standard"
  account_replication_type = "LRS"


}