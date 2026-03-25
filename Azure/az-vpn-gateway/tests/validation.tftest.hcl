mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
}

run "rejects_weak_ike_encryption_des" {
  command = plan

  variables {
    vpn_gateways = {
      bad = {
        name = "vpngw-bad"
        sku  = "VpnGw1"
        ip_configuration = {
          name                 = "vnetGatewayConfig"
          subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/GatewaySubnet"
          public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/pip-vpngw-bad"
        }
        connections = {
          weak = {
            name                      = "conn-weak"
            type                      = "IPsec"
            shared_key                = "test"
            ipsec_policy = {
              dh_group         = "DHGroup14"
              ike_encryption   = "DES"
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

  expect_failures = [var.vpn_gateways]
}

run "rejects_weak_ipsec_encryption_des" {
  command = plan

  variables {
    vpn_gateways = {
      bad = {
        name = "vpngw-bad"
        sku  = "VpnGw1"
        ip_configuration = {
          name                 = "vnetGatewayConfig"
          subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/GatewaySubnet"
          public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/pip-vpngw-bad"
        }
        connections = {
          weak = {
            name                      = "conn-weak"
            type                      = "IPsec"
            shared_key                = "test"
            ipsec_policy = {
              dh_group         = "DHGroup14"
              ike_encryption   = "AES256"
              ike_integrity    = "SHA256"
              ipsec_encryption = "DES"
              ipsec_integrity  = "SHA256"
              pfs_group        = "PFS14"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.vpn_gateways]
}
