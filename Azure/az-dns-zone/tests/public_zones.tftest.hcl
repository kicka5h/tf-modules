mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"

  dns_zones = {
    contoso = {
      name = "contoso.com"
      type = "public"
    }
    example = {
      name = "example.com"
      type = "public"
    }
  }
}

run "creates_multiple_public_zones" {
  command = plan

  assert {
    condition     = length(azurerm_dns_zone.public) == 2
    error_message = "Expected 2 public DNS zones"
  }

  assert {
    condition     = azurerm_dns_zone.public["contoso"].name == "contoso.com"
    error_message = "Expected public zone name to be contoso.com"
  }

  assert {
    condition     = azurerm_dns_zone.public["example"].name == "example.com"
    error_message = "Expected public zone name to be example.com"
  }
}

run "no_private_zones_created" {
  command = plan

  assert {
    condition     = length(azurerm_private_dns_zone.private) == 0
    error_message = "Expected no private DNS zones when only public zones are defined"
  }

  assert {
    condition     = length(azurerm_private_dns_zone_virtual_network_link.this) == 0
    error_message = "Expected no vnet links when only public zones are defined"
  }
}
