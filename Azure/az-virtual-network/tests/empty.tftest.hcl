mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
  vnets               = {}
}

run "no_resources_created_with_empty_input" {
  command = plan

  assert {
    condition     = length(azurerm_virtual_network.this) == 0
    error_message = "Expected no VNets with empty input"
  }

  assert {
    condition     = length(azurerm_subnet.this) == 0
    error_message = "Expected no subnets with empty input"
  }
}
