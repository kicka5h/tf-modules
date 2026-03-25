mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  dns_zones           = {}
}

run "no_resources_created_with_empty_input" {
  command = plan

  assert {
    condition     = length(azurerm_dns_zone.public) == 0
    error_message = "Expected no public zones with empty input"
  }

  assert {
    condition     = length(azurerm_private_dns_zone.private) == 0
    error_message = "Expected no private zones with empty input"
  }

  assert {
    condition     = length(azurerm_private_dns_zone_virtual_network_link.this) == 0
    error_message = "Expected no vnet links with empty input"
  }
}
