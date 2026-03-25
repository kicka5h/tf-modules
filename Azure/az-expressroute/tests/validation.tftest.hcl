mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  expressroute_circuits = {
    bad_tier = {
      name                  = "er-bad"
      service_provider_name = "Equinix"
      peering_location      = "Silicon Valley"
      bandwidth_in_mbps     = 50
      sku = {
        tier   = "InvalidTier"
        family = "MeteredData"
      }
    }
  }
}

run "rejects_invalid_sku_tier" {
  command         = plan
  expect_failures = [var.expressroute_circuits]
}

run "rejects_microsoft_peering_without_config" {
  command         = plan
  expect_failures = [var.expressroute_circuits]

  variables {
    expressroute_circuits = {
      bad_peering = {
        name                  = "er-bad-peering"
        service_provider_name = "Equinix"
        peering_location      = "Silicon Valley"
        bandwidth_in_mbps     = 50
        sku = {
          tier   = "Standard"
          family = "MeteredData"
        }
        peerings = {
          ms = {
            peering_type                  = "MicrosoftPeering"
            vlan_id                       = 200
            primary_peer_address_prefix   = "123.0.0.0/30"
            secondary_peer_address_prefix = "123.0.0.4/30"
          }
        }
      }
    }
  }
}
