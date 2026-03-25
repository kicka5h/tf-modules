mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  route_tables = {
    spoke = {
      name                          = "rt-spoke"
      bgp_route_propagation_enabled = false
      routes = {
        to_internet = {
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = "10.0.2.4"
        }
        to_onprem = {
          address_prefix = "172.16.0.0/12"
          next_hop_type  = "VirtualNetworkGateway"
        }
      }
    }
    hub = {
      name = "rt-hub"
      routes = {
        blackhole = {
          address_prefix = "192.168.0.0/16"
          next_hop_type  = "None"
        }
      }
    }
  }
}

run "creates_multiple_route_tables" {
  command = plan

  assert {
    condition     = length(azurerm_route_table.this) == 2
    error_message = "Expected 2 route tables"
  }

  assert {
    condition     = azurerm_route_table.this["spoke"].name == "rt-spoke"
    error_message = "Expected spoke route table name to be rt-spoke"
  }

  assert {
    condition     = azurerm_route_table.this["hub"].name == "rt-hub"
    error_message = "Expected hub route table name to be rt-hub"
  }
}

run "creates_all_routes" {
  command = plan

  assert {
    condition     = length(azurerm_route.this) == 3
    error_message = "Expected 3 routes across both route tables"
  }

  assert {
    condition     = azurerm_route.this["spoke-to_internet"].address_prefix == "0.0.0.0/0"
    error_message = "Expected default route address prefix"
  }

  assert {
    condition     = azurerm_route.this["spoke-to_internet"].next_hop_type == "VirtualAppliance"
    error_message = "Expected next hop type to be VirtualAppliance"
  }

  assert {
    condition     = azurerm_route.this["spoke-to_internet"].next_hop_in_ip_address == "10.0.2.4"
    error_message = "Expected next hop IP to be the firewall"
  }

  assert {
    condition     = azurerm_route.this["hub-blackhole"].next_hop_type == "None"
    error_message = "Expected blackhole route next hop type to be None"
  }
}

run "bgp_propagation_settings" {
  command = plan

  assert {
    condition     = azurerm_route_table.this["spoke"].bgp_route_propagation_enabled == false
    error_message = "Expected BGP propagation disabled on spoke"
  }

  assert {
    condition     = azurerm_route_table.this["hub"].bgp_route_propagation_enabled == true
    error_message = "Expected BGP propagation enabled on hub (default)"
  }
}

run "sets_location_and_resource_group" {
  command = plan

  assert {
    condition     = azurerm_route_table.this["spoke"].location == "eastus2"
    error_message = "Expected location to be eastus2"
  }

  assert {
    condition     = azurerm_route_table.this["spoke"].resource_group_name == "rg-test"
    error_message = "Expected resource group to be rg-test"
  }
}
