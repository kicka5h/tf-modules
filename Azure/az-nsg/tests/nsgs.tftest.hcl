mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  nsgs = {
    web = {
      name = "nsg-web"
      rules = {
        allow_https = {
          priority                   = 200
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
        allow_ssh = {
          priority                   = 210
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "22"
          source_address_prefix      = "10.0.0.0/8"
          destination_address_prefix = "*"
          description                = "Allow SSH from internal network"
        }
      }
    }
    db = {
      name = "nsg-db"
      rules = {
        deny_all_inbound = {
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      }
    }
  }
}

run "creates_multiple_nsgs" {
  command = plan

  assert {
    condition     = length(azurerm_network_security_group.this) == 2
    error_message = "Expected 2 NSGs"
  }

  assert {
    condition     = azurerm_network_security_group.this["web"].name == "nsg-web"
    error_message = "Expected web NSG name to be nsg-web"
  }

  assert {
    condition     = azurerm_network_security_group.this["db"].name == "nsg-db"
    error_message = "Expected db NSG name to be nsg-db"
  }
}

run "creates_all_rules" {
  command = plan

  assert {
    condition     = length(azurerm_network_security_rule.this) == 3
    error_message = "Expected 3 rules across both NSGs"
  }

  assert {
    condition     = azurerm_network_security_rule.this["web-allow_https"].priority == 200
    error_message = "Expected HTTPS rule priority to be 100"
  }

  assert {
    condition     = azurerm_network_security_rule.this["web-allow_https"].direction == "Inbound"
    error_message = "Expected HTTPS rule direction to be Inbound"
  }

  assert {
    condition     = azurerm_network_security_rule.this["web-allow_https"].access == "Allow"
    error_message = "Expected HTTPS rule access to be Allow"
  }

  assert {
    condition     = azurerm_network_security_rule.this["web-allow_https"].protocol == "Tcp"
    error_message = "Expected HTTPS rule protocol to be Tcp"
  }

  assert {
    condition     = azurerm_network_security_rule.this["web-allow_https"].destination_port_range == "443"
    error_message = "Expected HTTPS rule destination port to be 443"
  }

  assert {
    condition     = azurerm_network_security_rule.this["web-allow_ssh"].description == "Allow SSH from internal network"
    error_message = "Expected SSH rule to have description"
  }

  assert {
    condition     = azurerm_network_security_rule.this["db-deny_all_inbound"].access == "Deny"
    error_message = "Expected deny rule access to be Deny"
  }

  assert {
    condition     = azurerm_network_security_rule.this["db-deny_all_inbound"].protocol == "*"
    error_message = "Expected deny rule protocol to be *"
  }
}

run "sets_location_and_resource_group" {
  command = plan

  assert {
    condition     = azurerm_network_security_group.this["web"].location == "eastus2"
    error_message = "Expected location to be eastus2"
  }

  assert {
    condition     = azurerm_network_security_group.this["web"].resource_group_name == "rg-test"
    error_message = "Expected resource group to be rg-test"
  }
}
