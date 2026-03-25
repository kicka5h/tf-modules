resource_group_name = "rg-network"
location            = "eastus2"

expressroute_circuits = {
  dc_primary = {
    name                  = "er-dc-primary"
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

  dc_secondary = {
    name                  = "er-dc-secondary"
    service_provider_name = "Megaport"
    peering_location      = "Washington DC"
    bandwidth_in_mbps     = 2000
    sku = {
      tier   = "Premium"
      family = "UnlimitedData"
    }
    peerings = {
      private = {
        peering_type                  = "AzurePrivatePeering"
        vlan_id                       = 200
        primary_peer_address_prefix   = "10.1.0.0/30"
        secondary_peer_address_prefix = "10.1.0.4/30"
        peer_asn                      = 65001
      }
      microsoft = {
        peering_type                  = "MicrosoftPeering"
        vlan_id                       = 300
        primary_peer_address_prefix   = "123.0.0.0/30"
        secondary_peer_address_prefix = "123.0.0.4/30"
        peer_asn                      = 65001
        microsoft_peering_config = {
          advertised_public_prefixes = ["123.0.0.0/30", "123.0.0.4/30"]
        }
      }
    }
  }
}

tags = {
  environment = "production"
  managed_by  = "terraform"
}
