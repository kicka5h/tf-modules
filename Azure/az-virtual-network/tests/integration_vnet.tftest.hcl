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
  resource_group_name = "rg-vnet-inttest"
  location            = "eastus2"

  vnets = {
    test = {
      name          = "vnet-integration-test"
      address_space = ["10.0.0.0/16"]
      subnets = {
        default = {
          address_prefixes = ["10.0.1.0/24"]
        }
        app = {
          address_prefixes  = ["10.0.2.0/24"]
          service_endpoints = ["Microsoft.Storage"]
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

run "apply_vnet_module" {
  command = apply

  assert {
    condition     = length(azurerm_virtual_network.this) == 1
    error_message = "Expected 1 VNet to be created"
  }

  assert {
    condition     = azurerm_virtual_network.this["test"].name == "vnet-integration-test"
    error_message = "Expected VNet name to be vnet-integration-test"
  }

  assert {
    condition     = length(azurerm_subnet.this) == 2
    error_message = "Expected 2 subnets to be created"
  }

  assert {
    condition     = azurerm_virtual_network.this["test"].tags["Terraform"] == "true"
    error_message = "Expected default Terraform tag"
  }

  assert {
    condition     = azurerm_virtual_network.this["test"].tags["environment"] == "integration-test"
    error_message = "Expected custom tag"
  }
}
