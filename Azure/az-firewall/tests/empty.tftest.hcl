mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
  firewalls           = {}
}

run "no_resources_created_with_empty_input" {
  command = plan

  assert {
    condition     = length(azurerm_firewall.this) == 0
    error_message = "Expected no firewalls with empty input"
  }

  assert {
    condition     = length(azurerm_firewall_policy.this) == 0
    error_message = "Expected no firewall policies with empty input"
  }

  assert {
    condition     = length(azurerm_firewall_policy_rule_collection_group.this) == 0
    error_message = "Expected no rule collection groups with empty input"
  }
}
