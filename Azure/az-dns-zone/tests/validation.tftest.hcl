mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"

  dns_zones = {
    bad_zone = {
      name = "contoso.com"
      type = "invalid"
    }
  }
}

run "rejects_invalid_zone_type" {
  command         = plan
  expect_failures = [var.dns_zones]
}
