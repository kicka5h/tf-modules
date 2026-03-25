mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
  storage_accounts    = {}
}

run "no_resources_created_with_empty_input" {
  command = plan

  assert {
    condition     = length(azurerm_storage_account.this) == 0
    error_message = "Expected no storage accounts with empty input"
  }
}
