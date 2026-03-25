resource_group_name = "rg-network"
location            = "eastus2"

firewalls = {
  hub = {
    name              = "fw-hub"
    sku_name          = "AZFW_VNet"
    sku_tier          = "Standard"
    threat_intel_mode = "Alert"
    zones             = ["1", "2", "3"]
    ip_configuration = {
      name                 = "ipconfig"
      subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-hub/subnets/AzureFirewallSubnet"
      public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/publicIPAddresses/pip-fw-hub"
    }
    policy = {
      threat_intelligence_mode = "Deny"
      rule_collection_groups = {
        default = {
          name     = "rcg-default"
          priority = 300  # must be >= 300 (100-299 reserved for module-enforced blocklists)
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
            deny_all = {
              name     = "deny-all"
              priority = 1000
              action   = "Deny"
              rules = {
                all = {
                  name                  = "deny-all-outbound"
                  source_addresses      = ["*"]
                  destination_addresses = ["*"]
                  destination_ports     = ["*"]
                  protocols             = ["Any"]
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
                microsoft = {
                  name              = "allow-microsoft"
                  destination_fqdns = ["*.microsoft.com", "*.azure.com"]
                  protocols = [
                    { type = "Https", port = 443 }
                  ]
                }
                updates = {
                  name              = "allow-updates"
                  destination_fqdns = ["*.ubuntu.com", "*.windowsupdate.com"]
                  protocols = [
                    { type = "Http", port = 80 },
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

# Note: Ultimate Hosts Blacklist FQDN deny rules are automatically enforced
# on every firewall with an inline policy. Up to 1000 FQDNs by default.
# Set fqdn_blocklist_max = 0 to disable (not recommended).

tags = {
  environment = "production"
  managed_by  = "terraform"
}
