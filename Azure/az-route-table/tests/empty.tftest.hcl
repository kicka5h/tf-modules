mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
  route_tables        = {}
}

run "no_resources_created_with_empty_input" {
  command = plan

  assert {
    condition     = length(azurerm_route_table.this) == 0
    error_message = "Expected no route tables with empty input"
  }

  assert {
    condition     = length(azurerm_route.this) == 0
    error_message = "Expected no routes with empty input"
  }

  assert {
    condition     = length(azurerm_subnet_route_table_association.this) == 0
    error_message = "Expected no subnet associations with empty input"
  }
}
