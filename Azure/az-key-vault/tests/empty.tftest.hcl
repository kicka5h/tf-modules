mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
  key_vaults          = {}
}

run "no_resources_created_with_empty_input" {
  command = plan

  assert {
    condition     = length(azurerm_key_vault.this) == 0
    error_message = "Expected no key vaults with empty input"
  }

  assert {
    condition     = length(azurerm_key_vault_access_policy.this) == 0
    error_message = "Expected no access policies with empty input"
  }
}
