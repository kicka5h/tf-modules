mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  container_registries = {
    main = {
      name = "crtestmain"
      sku  = "Premium"
      georeplications = {
        westus2 = {
          location                = "westus2"
          zone_redundancy_enabled = true
        }
      }
    }
  }
}

run "creates_premium_registry" {
  command = plan

  assert {
    condition     = length(azurerm_container_registry.this) == 1
    error_message = "Expected 1 container registry"
  }

  assert {
    condition     = azurerm_container_registry.this["main"].name == "crtestmain"
    error_message = "Expected registry name to be crtestmain"
  }

  assert {
    condition     = azurerm_container_registry.this["main"].sku == "Premium"
    error_message = "Expected SKU to be Premium"
  }
}

run "sets_location_and_resource_group" {
  command = plan

  assert {
    condition     = azurerm_container_registry.this["main"].location == "eastus2"
    error_message = "Expected location to be eastus2"
  }

  assert {
    condition     = azurerm_container_registry.this["main"].resource_group_name == "rg-test"
    error_message = "Expected resource group to be rg-test"
  }
}

run "admin_disabled_by_default" {
  command = plan

  assert {
    condition     = azurerm_container_registry.this["main"].admin_enabled == false
    error_message = "Expected admin_enabled to be false"
  }
}

run "public_access_disabled_by_default" {
  command = plan

  assert {
    condition     = azurerm_container_registry.this["main"].public_network_access_enabled == false
    error_message = "Expected public_network_access_enabled to be false"
  }
}

run "zone_redundancy_enabled_by_default" {
  command = plan

  assert {
    condition     = azurerm_container_registry.this["main"].zone_redundancy_enabled == true
    error_message = "Expected zone_redundancy_enabled to be true"
  }
}
