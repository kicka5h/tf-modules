mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
  service_plans       = {}
  web_apps            = {}
}

run "no_resources_created_with_empty_input" {
  command = plan

  assert {
    condition     = length(azurerm_service_plan.this) == 0
    error_message = "Expected no service plans with empty input"
  }
}
