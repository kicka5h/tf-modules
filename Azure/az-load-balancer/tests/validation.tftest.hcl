mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  load_balancers = {
    bad = {
      name = "lb-bad"
      sku  = "InvalidSku"
      frontend_ip_configurations = {
        primary = {
          name                 = "fe-primary"
          public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/pip-lb"
        }
      }
    }
  }
}

run "rejects_invalid_sku" {
  command         = plan
  expect_failures = [var.load_balancers]
}
