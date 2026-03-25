mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  expressroute_circuits = {
    primary = {
      name                  = "er-primary"
      service_provider_name = "Equinix"
      peering_location      = "Silicon Valley"
      bandwidth_in_mbps     = 1000
      sku = {
        tier   = "Standard"
        family = "MeteredData"
      }
      peerings = {
        private = {
          peering_type                  = "AzurePrivatePeering"
          vlan_id                       = 100
          primary_peer_address_prefix   = "10.0.0.0/30"
          secondary_peer_address_prefix = "10.0.0.4/30"
          peer_asn                      = 65000
        }
      }
    }
  }
}

run "creates_circuit" {
  command = plan

  assert {
    condition     = length(azurerm_express_route_circuit.this) == 1
    error_message = "Expected 1 ExpressRoute circuit"
  }

  assert {
    condition     = azurerm_express_route_circuit.this["primary"].name == "er-primary"
    error_message = "Expected circuit name to be er-primary"
  }

  assert {
    condition     = azurerm_express_route_circuit.this["primary"].service_provider_name == "Equinix"
    error_message = "Expected service provider to be Equinix"
  }

  assert {
    condition     = azurerm_express_route_circuit.this["primary"].peering_location == "Silicon Valley"
    error_message = "Expected peering location to be Silicon Valley"
  }

  assert {
    condition     = azurerm_express_route_circuit.this["primary"].bandwidth_in_mbps == 1000
    error_message = "Expected bandwidth to be 1000 Mbps"
  }

  assert {
    condition     = azurerm_express_route_circuit.this["primary"].location == "eastus2"
    error_message = "Expected location to be eastus2"
  }

  assert {
    condition     = azurerm_express_route_circuit.this["primary"].resource_group_name == "rg-test"
    error_message = "Expected resource group to be rg-test"
  }
}

run "creates_private_peering" {
  command = plan

  assert {
    condition     = length(azurerm_express_route_circuit_peering.this) == 1
    error_message = "Expected 1 peering"
  }

  assert {
    condition     = azurerm_express_route_circuit_peering.this["primary-private"].peering_type == "AzurePrivatePeering"
    error_message = "Expected peering type to be AzurePrivatePeering"
  }

  assert {
    condition     = azurerm_express_route_circuit_peering.this["primary-private"].vlan_id == 100
    error_message = "Expected VLAN ID to be 100"
  }

  assert {
    condition     = azurerm_express_route_circuit_peering.this["primary-private"].primary_peer_address_prefix == "10.0.0.0/30"
    error_message = "Expected primary peer address prefix to be 10.0.0.0/30"
  }

  assert {
    condition     = azurerm_express_route_circuit_peering.this["primary-private"].secondary_peer_address_prefix == "10.0.0.4/30"
    error_message = "Expected secondary peer address prefix to be 10.0.0.4/30"
  }

  assert {
    condition     = azurerm_express_route_circuit_peering.this["primary-private"].peer_asn == 65000
    error_message = "Expected peer ASN to be 65000"
  }
}

run "classic_operations_default_false" {
  command = plan

  assert {
    condition     = azurerm_express_route_circuit.this["primary"].allow_classic_operations == false
    error_message = "Expected allow_classic_operations to default to false"
  }
}
