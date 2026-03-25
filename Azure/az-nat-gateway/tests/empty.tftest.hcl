mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
  nat_gateways        = {}
}

run "no_resources_created_with_empty_input" {
  command = plan

  assert {
    condition     = length(azurerm_nat_gateway.this) == 0
    error_message = "Expected no NAT gateways with empty input"
  }

  assert {
    condition     = length(azurerm_nat_gateway_public_ip_association.this) == 0
    error_message = "Expected no public IP associations with empty input"
  }

  assert {
    condition     = length(azurerm_nat_gateway_public_ip_prefix_association.this) == 0
    error_message = "Expected no public IP prefix associations with empty input"
  }

  assert {
    condition     = length(azurerm_subnet_nat_gateway_association.this) == 0
    error_message = "Expected no subnet associations with empty input"
  }
}
