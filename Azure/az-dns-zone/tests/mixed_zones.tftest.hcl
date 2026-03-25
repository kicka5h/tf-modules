mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"

  dns_zones = {
    public_main = {
      name = "contoso.com"
      type = "public"
    }
    public_api = {
      name = "api.contoso.com"
      type = "public"
    }
    private_internal = {
      name = "internal.contoso.com"
      type = "private"
      vnet_links = {
        hub = {
          virtual_network_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-hub"
          registration_enabled = true
        }
      }
    }
    private_db = {
      name = "db.contoso.com"
      type = "private"
    }
  }
}

run "creates_both_public_and_private_zones" {
  command = plan

  assert {
    condition     = length(azurerm_dns_zone.public) == 2
    error_message = "Expected 2 public DNS zones"
  }

  assert {
    condition     = length(azurerm_private_dns_zone.private) == 2
    error_message = "Expected 2 private DNS zones"
  }

  assert {
    condition     = length(azurerm_private_dns_zone_virtual_network_link.this) == 1
    error_message = "Expected 1 vnet link"
  }
}

run "resource_group_is_set_on_all_resources" {
  command = plan

  assert {
    condition     = azurerm_dns_zone.public["public_main"].resource_group_name == "rg-test"
    error_message = "Public zone resource group mismatch"
  }

  assert {
    condition     = azurerm_private_dns_zone.private["private_internal"].resource_group_name == "rg-test"
    error_message = "Private zone resource group mismatch"
  }
}
