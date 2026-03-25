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
  resource_group_name = "rg-kv-inttest"
  location            = "eastus2"

  key_vaults = {
    test = {
      name     = "kv-inttest-001"
      sku_name = "premium"
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

run "apply_keyvault_module" {
  command = apply

  assert {
    condition     = length(azurerm_key_vault.this) == 1
    error_message = "Expected 1 Key Vault to be created"
  }

  assert {
    condition     = azurerm_key_vault.this["test"].name == "kv-inttest-001"
    error_message = "Expected Key Vault name to match"
  }

  assert {
    condition     = azurerm_key_vault.this["test"].sku_name == "premium"
    error_message = "Expected premium SKU"
  }

  assert {
    condition     = azurerm_key_vault.this["test"].purge_protection_enabled == true
    error_message = "Expected purge protection enabled"
  }

  assert {
    condition     = azurerm_key_vault.this["test"].enable_rbac_authorization == true
    error_message = "Expected RBAC authorization enabled"
  }

  assert {
    condition     = azurerm_key_vault.this["test"].public_network_access_enabled == false
    error_message = "Expected public network access disabled"
  }
}
