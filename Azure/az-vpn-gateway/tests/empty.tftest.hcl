mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
  vpn_gateways        = {}
}

run "no_resources_created_with_empty_input" {
  command = plan

  assert {
    condition     = length(azurerm_virtual_network_gateway.this) == 0
    error_message = "Expected no VPN gateways with empty input"
  }

  assert {
    condition     = length(azurerm_local_network_gateway.this) == 0
    error_message = "Expected no local network gateways with empty input"
  }

  assert {
    condition     = length(azurerm_virtual_network_gateway_connection.this) == 0
    error_message = "Expected no connections with empty input"
  }
}
