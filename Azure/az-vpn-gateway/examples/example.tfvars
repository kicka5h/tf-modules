resource_group_name = "rg-network"
location            = "eastus2"

vpn_gateways = {
  hub = {
    name       = "vpngw-hub-eastus2"
    sku        = "VpnGw2AZ"
    enable_bgp = true
    bgp_settings = {
      asn = 65515
    }
    ip_configuration = {
      name                 = "vnetGatewayConfig"
      subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-hub/subnets/GatewaySubnet"
      public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/publicIPAddresses/pip-vpngw-hub"
    }
    local_network_gateways = {
      onprem_dc1 = {
        name            = "lgw-onprem-dc1"
        gateway_address = "203.0.113.1"
        address_space   = ["10.100.0.0/16", "10.101.0.0/16"]
      }
      onprem_dc2 = {
        name            = "lgw-onprem-dc2"
        gateway_address = "198.51.100.1"
        address_space   = ["10.200.0.0/16"]
        bgp_settings = {
          asn                 = 65020
          bgp_peering_address = "10.200.0.1"
        }
      }
    }
    connections = {
      to_dc1 = {
        name                      = "conn-to-dc1"
        type                      = "IPsec"
        local_network_gateway_key = "onprem_dc1"
        shared_key                = "SuperSecretKey-DC1-2026!"
        connection_protocol       = "IKEv2"
        ipsec_policy = {
          dh_group         = "DHGroup14"
          ike_encryption   = "AES256"
          ike_integrity    = "SHA256"
          ipsec_encryption = "AES256"
          ipsec_integrity  = "SHA256"
          pfs_group        = "PFS14"
          sa_lifetime      = 28800
          sa_datasize      = 102400000
        }
      }
      to_dc2 = {
        name                      = "conn-to-dc2"
        type                      = "IPsec"
        local_network_gateway_key = "onprem_dc2"
        shared_key                = "SuperSecretKey-DC2-2026!"
        enable_bgp                = true
        connection_protocol       = "IKEv2"
        ipsec_policy = {
          dh_group         = "ECP384"
          ike_encryption   = "GCMAES256"
          ike_integrity    = "GCMAES256"
          ipsec_encryption = "GCMAES256"
          ipsec_integrity  = "GCMAES256"
          pfs_group        = "ECP384"
          sa_lifetime      = 27000
          sa_datasize      = 102400000
        }
      }
    }
  }
}

tags = {
  environment = "production"
  managed_by  = "terraform"
}
