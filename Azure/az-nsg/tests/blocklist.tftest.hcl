mock_provider "azurerm" {}

# Mock the http provider so we don't make real HTTP calls during tests
mock_provider "http" {
  mock_data "http" {
    defaults = {
      response_body = <<-EOT
        ; Blocklist test data
        # Comment line
        1.2.3.0/24 ; SBL000001
        4.5.6.0/16 ; SBL000002

        7.8.9.0/24 ; SBL000003
      EOT
    }
  }
}

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
      }
    }
    app = {
      name  = "nsg-app"
      rules = {}
    }
  }
}

run "spamhaus_inbound_rule_on_every_nsg" {
  command = plan

  assert {
    condition     = length(azurerm_network_security_rule.spamhaus_deny_inbound) == 2
    error_message = "Expected spamhaus inbound deny rule on every NSG (2)"
  }

  assert {
    condition     = azurerm_network_security_rule.spamhaus_deny_inbound["web"].direction == "Inbound"
    error_message = "Expected inbound direction"
  }

  assert {
    condition     = azurerm_network_security_rule.spamhaus_deny_inbound["web"].access == "Deny"
    error_message = "Expected Deny access"
  }

  assert {
    condition     = azurerm_network_security_rule.spamhaus_deny_inbound["web"].priority == 100
    error_message = "Expected priority 100"
  }

  assert {
    condition     = azurerm_network_security_rule.spamhaus_deny_inbound["web"].protocol == "*"
    error_message = "Expected protocol *"
  }
}

run "spamhaus_outbound_rule_on_every_nsg" {
  command = plan

  assert {
    condition     = length(azurerm_network_security_rule.spamhaus_deny_outbound) == 2
    error_message = "Expected spamhaus outbound deny rule on every NSG (2)"
  }

  assert {
    condition     = azurerm_network_security_rule.spamhaus_deny_outbound["app"].direction == "Outbound"
    error_message = "Expected outbound direction"
  }

  assert {
    condition     = azurerm_network_security_rule.spamhaus_deny_outbound["app"].access == "Deny"
    error_message = "Expected Deny access"
  }
}

run "spamhaus_does_not_affect_user_rules" {
  command = plan

  assert {
    condition     = length(azurerm_network_security_rule.this) == 1
    error_message = "Expected 1 user-defined rule (allow_https on web NSG)"
  }

  assert {
    condition     = azurerm_network_security_rule.this["web-allow_https"].access == "Allow"
    error_message = "Expected existing rule to remain unchanged"
  }
}

run "spamhaus_parses_cidrs_from_drop_and_edrop" {
  command = plan

  # Both DROP and EDROP are mocked with the same 3-CIDR response
  # After distinct(), we get 3 unique CIDRs
  assert {
    condition     = length(azurerm_network_security_rule.spamhaus_deny_inbound["web"].source_address_prefixes) == 3
    error_message = "Expected 3 CIDRs parsed from mocked Spamhaus response (skipping comments and blank lines)"
  }
}
