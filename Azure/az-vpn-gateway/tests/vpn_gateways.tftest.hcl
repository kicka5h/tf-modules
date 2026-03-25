mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  vpn_gateways = {
    hub = {
      name       = "vpngw-hub"
      sku        = "VpnGw2AZ"
      enable_bgp = true
      bgp_settings = {
        asn = 65515
      }
      ip_configuration = {
        name                 = "vnetGatewayConfig"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-hub/subnets/GatewaySubnet"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/pip-vpngw-hub"
      }
      local_network_gateways = {
        onprem_dc1 = {
          name            = "lgw-onprem-dc1"
          gateway_address = "203.0.113.1"
          address_space   = ["10.100.0.0/16", "10.101.0.0/16"]
        }
      }
      connections = {
        to_dc1 = {
          name                      = "conn-to-dc1"
          type                      = "IPsec"
          local_network_gateway_key = "onprem_dc1"
          shared_key                = "SuperSecretKey123!"
          ipsec_policy = {
            dh_group         = "DHGroup14"
            ike_encryption   = "AES256"
            ike_integrity    = "SHA256"
            ipsec_encryption = "AES256"
            ipsec_integrity  = "SHA256"
            pfs_group        = "PFS14"
          }
        }
      }
    }
  }
}

run "creates_vpn_gateway" {
  command = plan

  assert {
    condition     = length(azurerm_virtual_network_gateway.this) == 1
    error_message = "Expected 1 VPN gateway"
  }

  assert {
    condition     = azurerm_virtual_network_gateway.this["hub"].name == "vpngw-hub"
    error_message = "Expected VPN gateway name to be vpngw-hub"
  }

  assert {
    condition     = azurerm_virtual_network_gateway.this["hub"].sku == "VpnGw2AZ"
    error_message = "Expected SKU to be VpnGw2AZ"
  }

  assert {
    condition     = azurerm_virtual_network_gateway.this["hub"].enable_bgp == true
    error_message = "Expected BGP to be enabled"
  }

  assert {
    condition     = azurerm_virtual_network_gateway.this["hub"].type == "Vpn"
    error_message = "Expected gateway type to be Vpn"
  }

  assert {
    condition     = azurerm_virtual_network_gateway.this["hub"].vpn_type == "RouteBased"
    error_message = "Expected VPN type to be RouteBased"
  }

  assert {
    condition     = azurerm_virtual_network_gateway.this["hub"].generation == "Generation2"
    error_message = "Expected generation to be Generation2"
  }
}

run "creates_local_network_gateway" {
  command = plan

  assert {
    condition     = length(azurerm_local_network_gateway.this) == 1
    error_message = "Expected 1 local network gateway"
  }

  assert {
    condition     = azurerm_local_network_gateway.this["hub-onprem_dc1"].name == "lgw-onprem-dc1"
    error_message = "Expected local network gateway name to be lgw-onprem-dc1"
  }

  assert {
    condition     = azurerm_local_network_gateway.this["hub-onprem_dc1"].gateway_address == "203.0.113.1"
    error_message = "Expected gateway address to be 203.0.113.1"
  }
}

run "creates_connection" {
  command = plan

  assert {
    condition     = length(azurerm_virtual_network_gateway_connection.this) == 1
    error_message = "Expected 1 connection"
  }

  assert {
    condition     = azurerm_virtual_network_gateway_connection.this["hub-to_dc1"].name == "conn-to-dc1"
    error_message = "Expected connection name to be conn-to-dc1"
  }

  assert {
    condition     = azurerm_virtual_network_gateway_connection.this["hub-to_dc1"].type == "IPsec"
    error_message = "Expected connection type to be IPsec"
  }

  assert {
    condition     = azurerm_virtual_network_gateway_connection.this["hub-to_dc1"].enable_bgp == false
    error_message = "Expected BGP on connection to be disabled by default"
  }
}

run "sets_location_and_resource_group" {
  command = plan

  assert {
    condition     = azurerm_virtual_network_gateway.this["hub"].location == "eastus2"
    error_message = "Expected location to be eastus2"
  }

  assert {
    condition     = azurerm_virtual_network_gateway.this["hub"].resource_group_name == "rg-test"
    error_message = "Expected resource group to be rg-test"
  }
}
