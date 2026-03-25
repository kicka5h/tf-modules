mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
  load_balancers      = {}
}

run "no_resources_created_with_empty_input" {
  command = plan

  assert {
    condition     = length(azurerm_lb.this) == 0
    error_message = "Expected no load balancers with empty input"
  }

  assert {
    condition     = length(azurerm_lb_backend_address_pool.this) == 0
    error_message = "Expected no backend pools with empty input"
  }

  assert {
    condition     = length(azurerm_lb_probe.this) == 0
    error_message = "Expected no probes with empty input"
  }

  assert {
    condition     = length(azurerm_lb_rule.this) == 0
    error_message = "Expected no rules with empty input"
  }

  assert {
    condition     = length(azurerm_lb_nat_rule.this) == 0
    error_message = "Expected no NAT rules with empty input"
  }

  assert {
    condition     = length(azurerm_lb_outbound_rule.this) == 0
    error_message = "Expected no outbound rules with empty input"
  }
}
