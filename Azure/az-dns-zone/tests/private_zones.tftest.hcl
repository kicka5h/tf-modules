mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"

  dns_zones = {
    internal = {
      name = "internal.contoso.com"
      type = "private"
      vnet_links = {
        hub = {
          virtual_network_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-hub"
          registration_enabled = true
        }
        spoke = {
          virtual_network_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-spoke"
          registration_enabled = false
        }
      }
    }
    database = {
      name = "db.contoso.com"
      type = "private"
    }
  }
}

run "creates_multiple_private_zones" {
  command = plan

  assert {
    condition     = length(azurerm_private_dns_zone.private) == 2
    error_message = "Expected 2 private DNS zones"
  }

  assert {
    condition     = azurerm_private_dns_zone.private["internal"].name == "internal.contoso.com"
    error_message = "Expected private zone name to be internal.contoso.com"
  }

  assert {
    condition     = azurerm_private_dns_zone.private["database"].name == "db.contoso.com"
    error_message = "Expected private zone name to be db.contoso.com"
  }
}

run "no_public_zones_created" {
  command = plan

  assert {
    condition     = length(azurerm_dns_zone.public) == 0
    error_message = "Expected no public DNS zones when only private zones are defined"
  }
}

run "creates_vnet_links_for_private_zones" {
  command = plan

  assert {
    condition     = length(azurerm_private_dns_zone_virtual_network_link.this) == 2
    error_message = "Expected 2 vnet links (both on the internal zone)"
  }

  assert {
    condition     = azurerm_private_dns_zone_virtual_network_link.this["internal-hub"].registration_enabled == true
    error_message = "Expected hub vnet link to have registration enabled"
  }

  assert {
    condition     = azurerm_private_dns_zone_virtual_network_link.this["internal-spoke"].registration_enabled == false
    error_message = "Expected spoke vnet link to have registration disabled"
  }
}
