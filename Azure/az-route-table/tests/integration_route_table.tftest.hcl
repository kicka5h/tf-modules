# Integration test — runs against LocalStack Azure with command = apply.
# Requires: IMAGE_NAME=localstack/localstack-azure-alpha localstack start

provider "azurerm" {
  features {}
  subscription_id                 = "00000000-0000-0000-0000-000000000000"
  tenant_id                       = "00000000-0000-0000-0000-000000000000"
  client_id                       = "00000000-0000-0000-0000-000000000000"
  client_secret                   = "mock-secret"
  metadata_host                   = "localhost.localstack.cloud:4566"
  resource_provider_registrations = "none"
}

variables {
  resource_group_name = "rg-rt-inttest"
  location            = "eastus2"

  route_tables = {
    spoke = {
      name                          = "rt-spoke-inttest"
      bgp_route_propagation_enabled = false
      routes = {
        to_firewall = {
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = "10.0.2.4"
        }
        to_vnet = {
          address_prefix = "10.0.0.0/8"
          next_hop_type  = "VnetLocal"
        }
      }
    }
  }

  tags = {
    environment = "integration-test"
  }
}

run "setup_resource_group" {
  command = apply

  module {
    source = "./tests/setup"
  }
}

run "apply_route_table_module" {
  command = apply

  assert {
    condition     = length(azurerm_route_table.this) == 1
    error_message = "Expected 1 route table to be created"
  }

  assert {
    condition     = azurerm_route_table.this["spoke"].name == "rt-spoke-inttest"
    error_message = "Expected route table name to be rt-spoke-inttest"
  }

  assert {
    condition     = azurerm_route_table.this["spoke"].bgp_route_propagation_enabled == false
    error_message = "Expected BGP propagation disabled"
  }

  assert {
    condition     = length(azurerm_route.this) == 2
    error_message = "Expected 2 routes to be created"
  }

  assert {
    condition     = azurerm_route.this["spoke-to_firewall"].next_hop_type == "VirtualAppliance"
    error_message = "Expected next hop type to be VirtualAppliance"
  }

  assert {
    condition     = azurerm_route.this["spoke-to_firewall"].next_hop_in_ip_address == "10.0.2.4"
    error_message = "Expected next hop IP to be 10.0.2.4"
  }
}
