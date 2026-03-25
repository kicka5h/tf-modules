mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  firewalls = {
    hub = {
      name     = "fw-hub"
      sku_name = "AZFW_VNet"
      sku_tier = "Standard"
      ip_configuration = {
        name                 = "ipconfig"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-hub/subnets/AzureFirewallSubnet"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/pip-fw-hub"
      }
      policy = {
        threat_intelligence_mode = "Deny"
        rule_collection_groups = {
          default = {
            name     = "rcg-default"
            priority = 300
            network_rule_collections = {
              allow_dns = {
                name     = "allow-dns"
                priority = 100
                action   = "Allow"
                rules = {
                  dns = {
                    name                  = "allow-dns-outbound"
                    destination_addresses = ["168.63.129.16"]
                    destination_ports     = ["53"]
                    protocols             = ["UDP", "TCP"]
                  }
                }
              }
            }
            application_rule_collections = {
              allow_web = {
                name     = "allow-web"
                priority = 200
                action   = "Allow"
                rules = {
                  https = {
                    name              = "allow-https"
                    destination_fqdns = ["*.microsoft.com"]
                    protocols = [
                      { type = "Https", port = 443 }
                    ]
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

run "creates_firewall" {
  command = plan

  assert {
    condition     = length(azurerm_firewall.this) == 1
    error_message = "Expected 1 firewall"
  }

  assert {
    condition     = azurerm_firewall.this["hub"].name == "fw-hub"
    error_message = "Expected firewall name to be fw-hub"
  }

  assert {
    condition     = azurerm_firewall.this["hub"].sku_name == "AZFW_VNet"
    error_message = "Expected sku_name to be AZFW_VNet"
  }

  assert {
    condition     = azurerm_firewall.this["hub"].sku_tier == "Standard"
    error_message = "Expected sku_tier to be Standard"
  }
}

run "creates_inline_policy" {
  command = plan

  assert {
    condition     = length(azurerm_firewall_policy.this) == 1
    error_message = "Expected 1 firewall policy"
  }

  assert {
    condition     = azurerm_firewall_policy.this["hub"].name == "fw-hub-policy"
    error_message = "Expected policy name to be fw-hub-policy"
  }

  assert {
    condition     = azurerm_firewall_policy.this["hub"].sku == "Standard"
    error_message = "Expected policy sku to match firewall sku_tier"
  }

  assert {
    condition     = azurerm_firewall_policy.this["hub"].threat_intelligence_mode == "Deny"
    error_message = "Expected threat_intelligence_mode to be Deny"
  }
}

run "creates_rule_collection_group" {
  command = plan

  assert {
    condition     = length(azurerm_firewall_policy_rule_collection_group.this) == 1
    error_message = "Expected 1 rule collection group"
  }

  assert {
    condition     = azurerm_firewall_policy_rule_collection_group.this["hub-default"].name == "rcg-default"
    error_message = "Expected rule collection group name to be rcg-default"
  }

  assert {
    condition     = azurerm_firewall_policy_rule_collection_group.this["hub-default"].priority == 300
    error_message = "Expected rule collection group priority to be 100"
  }
}

run "sets_location_and_resource_group" {
  command = plan

  assert {
    condition     = azurerm_firewall.this["hub"].location == "eastus2"
    error_message = "Expected location to be eastus2"
  }

  assert {
    condition     = azurerm_firewall.this["hub"].resource_group_name == "rg-test"
    error_message = "Expected resource group to be rg-test"
  }
}
