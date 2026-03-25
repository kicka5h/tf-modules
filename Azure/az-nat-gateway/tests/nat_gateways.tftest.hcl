mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  nat_gateways = {
    egress = {
      name                    = "natgw-egress"
      idle_timeout_in_minutes = 10
      zones                   = ["1", "2"]
    }
    shared = {
      name = "natgw-shared"
    }
  }
}

run "creates_multiple_nat_gateways" {
  command = plan

  assert {
    condition     = length(azurerm_nat_gateway.this) == 2
    error_message = "Expected 2 NAT gateways"
  }

  assert {
    condition     = azurerm_nat_gateway.this["egress"].name == "natgw-egress"
    error_message = "Expected egress NAT gateway name to be natgw-egress"
  }

  assert {
    condition     = azurerm_nat_gateway.this["shared"].name == "natgw-shared"
    error_message = "Expected shared NAT gateway name to be natgw-shared"
  }
}

run "sets_idle_timeout" {
  command = plan

  assert {
    condition     = azurerm_nat_gateway.this["egress"].idle_timeout_in_minutes == 10
    error_message = "Expected egress idle timeout to be 10"
  }

  assert {
    condition     = azurerm_nat_gateway.this["shared"].idle_timeout_in_minutes == 4
    error_message = "Expected shared idle timeout to be 4 (default)"
  }
}

run "sets_sku_name" {
  command = plan

  assert {
    condition     = azurerm_nat_gateway.this["egress"].sku_name == "Standard"
    error_message = "Expected SKU to be Standard"
  }
}

run "sets_zones" {
  command = plan

  assert {
    condition     = tolist(azurerm_nat_gateway.this["egress"].zones) == tolist(["1", "2"])
    error_message = "Expected egress zones to be [1, 2]"
  }
}

run "sets_location_and_resource_group" {
  command = plan

  assert {
    condition     = azurerm_nat_gateway.this["egress"].location == "eastus2"
    error_message = "Expected location to be eastus2"
  }

  assert {
    condition     = azurerm_nat_gateway.this["egress"].resource_group_name == "rg-test"
    error_message = "Expected resource group to be rg-test"
  }
}
