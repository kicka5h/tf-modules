mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
  nsgs                = {}
}

run "no_resources_created_with_empty_input" {
  command = plan

  assert {
    condition     = length(azurerm_network_security_group.this) == 0
    error_message = "Expected no NSGs with empty input"
  }

  assert {
    condition     = length(azurerm_network_security_rule.this) == 0
    error_message = "Expected no rules with empty input"
  }

  assert {
    condition     = length(azurerm_subnet_network_security_group_association.this) == 0
    error_message = "Expected no subnet associations with empty input"
  }
}
