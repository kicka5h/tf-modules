# Integration test — runs against LocalStack Azure with command = apply.
# Requires: IMAGE_NAME=localstack/localstack-azure-alpha localstack start

provider "azurerm" {
  features {}
  subscription_id                 = "00000000-0000-0000-0000-000000000000"
  tenant_id                       = "00000000-0000-0000-0000-000000000000"
  client_id                       = "00000000-0000-0000-0000-000000000000"
  client_secret                   = "mock-secret"
  metadata_host                   = "localhost.localstack.cloud:4566"
  resource_provider_registrations = "none"
}

variables {
  resource_group_name = "rg-nsg-inttest"
  location            = "eastus2"

  nsgs = {
    web = {
      name = "nsg-web-inttest"
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
          description                = "Allow HTTPS"
        }
        deny_all = {
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
          description                = "Deny all inbound"
        }
      }
    }
  }

  tags = {
    environment = "integration-test"
  }
}

run "setup_resource_group" {
  command = apply

  module {
    source = "./tests/setup"
  }
}

run "apply_nsg_module" {
  command = apply

  assert {
    condition     = length(azurerm_network_security_group.this) == 1
    error_message = "Expected 1 NSG to be created"
  }

  assert {
    condition     = azurerm_network_security_group.this["web"].name == "nsg-web-inttest"
    error_message = "Expected NSG name to be nsg-web-inttest"
  }

  assert {
    condition     = length(azurerm_network_security_rule.this) == 2
    error_message = "Expected 2 user-defined rules"
  }

  assert {
    condition     = azurerm_network_security_rule.this["web-allow_https"].priority == 200
    error_message = "Expected HTTPS rule priority to be 200"
  }

  assert {
    condition     = azurerm_network_security_rule.this["web-allow_https"].access == "Allow"
    error_message = "Expected HTTPS rule access to be Allow"
  }
}
