mock_provider "azurerm" {}

variables {
  resource_group_name  = "rg-test"
  location             = "eastus2"
  container_registries = {}
}

run "no_resources_created_with_empty_input" {
  command = plan

  assert {
    condition     = length(azurerm_container_registry.this) == 0
    error_message = "Expected no container registries with empty input"
  }
}
