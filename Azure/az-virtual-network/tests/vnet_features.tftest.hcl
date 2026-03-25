mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  vnets = {
    with_ddos = {
      name          = "vnet-ddos"
      address_space = ["10.0.0.0/16"]
      ddos_protection_plan = {
        id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sec/providers/Microsoft.Network/ddosProtectionPlans/ddos-plan"
        enable = true
      }
    }
    with_encryption = {
      name          = "vnet-encrypted"
      address_space = ["10.1.0.0/16"]
      encryption = {
        enforcement = "DropUnencrypted"
      }
    }
    with_flow_timeout = {
      name                    = "vnet-flow"
      address_space           = ["10.2.0.0/16"]
      flow_timeout_in_minutes = 10
    }
    plain = {
      name          = "vnet-plain"
      address_space = ["10.3.0.0/16"]
    }
  }
}

run "creates_all_vnets" {
  command = plan

  assert {
    condition     = length(azurerm_virtual_network.this) == 4
    error_message = "Expected 4 VNets"
  }
}

run "ddos_protection_plan_is_set" {
  command = plan

  assert {
    condition     = length(azurerm_virtual_network.this["with_ddos"].ddos_protection_plan) == 1
    error_message = "Expected DDoS protection plan on with_ddos VNet"
  }

  assert {
    condition     = length(azurerm_virtual_network.this["plain"].ddos_protection_plan) == 0
    error_message = "Expected no DDoS protection plan on plain VNet"
  }
}

run "encryption_is_set" {
  command = plan

  assert {
    condition     = length(azurerm_virtual_network.this["with_encryption"].encryption) == 1
    error_message = "Expected encryption on with_encryption VNet"
  }

  assert {
    condition     = length(azurerm_virtual_network.this["plain"].encryption) == 0
    error_message = "Expected no encryption on plain VNet"
  }
}

run "flow_timeout_is_set" {
  command = plan

  assert {
    condition     = azurerm_virtual_network.this["with_flow_timeout"].flow_timeout_in_minutes == 10
    error_message = "Expected flow timeout of 10 minutes"
  }
}
