mock_provider "azurerm" {}

variables {
  resource_group_name  = "rg-test"
  location             = "eastus2"
  application_gateways = {}
}

run "no_resources_created_with_empty_input" {
  command = plan

  assert {
    condition     = length(azurerm_application_gateway.this) == 0
    error_message = "Expected no application gateways with empty input"
  }
}
