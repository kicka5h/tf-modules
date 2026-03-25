mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  route_tables = {
    bad = {
      name = "rt-bad"
      routes = {
        invalid = {
          address_prefix = "0.0.0.0/0"
          next_hop_type  = "InvalidType"
        }
      }
    }
  }
}

run "rejects_invalid_next_hop_type" {
  command         = plan
  expect_failures = [var.route_tables]
}
