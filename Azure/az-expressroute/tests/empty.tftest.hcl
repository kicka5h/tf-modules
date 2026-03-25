mock_provider "azurerm" {}

variables {
  resource_group_name   = "rg-test"
  location              = "eastus2"
  expressroute_circuits = {}
}

run "no_resources_created_with_empty_input" {
  command = plan

  assert {
    condition     = length(azurerm_express_route_circuit.this) == 0
    error_message = "Expected no ExpressRoute circuits with empty input"
  }

  assert {
    condition     = length(azurerm_express_route_circuit_peering.this) == 0
    error_message = "Expected no peerings with empty input"
  }
}
