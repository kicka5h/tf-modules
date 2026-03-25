mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
}

run "rejects_reserved_rcg_priority" {
  command = plan

  variables {
    firewalls = {
      bad = {
        name = "fw-bad"
        ip_configuration = {
          name                 = "ipconfig"
          subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/AzureFirewallSubnet"
          public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/pip-fw-bad"
        }
        policy = {
          rule_collection_groups = {
            too_low = {
              name     = "rcg-bad"
              priority = 250
            }
          }
        }
      }
    }
  }

  expect_failures = [var.firewalls]
}

run "rejects_invalid_sku_tier" {
  command = plan

  variables {
    firewalls = {
      bad = {
        name     = "fw-bad"
        sku_tier = "InvalidTier"
        ip_configuration = {
          name                 = "ipconfig"
          subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/AzureFirewallSubnet"
          public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/pip-fw-bad"
        }
      }
    }
  }

  expect_failures = [var.firewalls]
}

run "rejects_invalid_sku_name" {
  command = plan

  variables {
    firewalls = {
      bad = {
        name     = "fw-bad"
        sku_name = "InvalidSku"
        ip_configuration = {
          name                 = "ipconfig"
          subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/AzureFirewallSubnet"
          public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/pip-fw-bad"
        }
      }
    }
  }

  expect_failures = [var.firewalls]
}

run "rejects_invalid_threat_intel_mode" {
  command = plan

  variables {
    firewalls = {
      bad = {
        name              = "fw-bad"
        threat_intel_mode = "InvalidMode"
        ip_configuration = {
          name                 = "ipconfig"
          subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/AzureFirewallSubnet"
          public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/pip-fw-bad"
        }
      }
    }
  }

  expect_failures = [var.firewalls]
}
