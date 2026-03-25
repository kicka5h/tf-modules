resource "azurerm_resource_group" "test" {
  name     = "rg-kv-inttest"
  location = "eastus2"
}

output "resource_group_name" {
  value = azurerm_resource_group.test.name
}

output "location" {
  value = azurerm_resource_group.test.location
}
