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
  resource_group_name = "rg-storage-inttest"
  location            = "eastus2"

  storage_accounts = {
    test = {
      name                     = "stinttest00000001"
      account_tier             = "Standard"
      account_replication_type = "GRS"
      containers = {
        data = {
          name = "data"
        }
        logs = {
          name = "logs"
        }
      }
      file_shares = {
        share1 = {
          name  = "share1"
          quota = 10
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

run "apply_storage_module" {
  command = apply

  assert {
    condition     = length(azurerm_storage_account.this) == 1
    error_message = "Expected 1 storage account to be created"
  }

  assert {
    condition     = azurerm_storage_account.this["test"].name == "stinttest00000001"
    error_message = "Expected storage account name to match"
  }

  assert {
    condition     = azurerm_storage_account.this["test"].account_tier == "Standard"
    error_message = "Expected Standard tier"
  }

  assert {
    condition     = azurerm_storage_account.this["test"].account_replication_type == "GRS"
    error_message = "Expected GRS replication"
  }

  assert {
    condition     = azurerm_storage_account.this["test"].min_tls_version == "TLS1_2"
    error_message = "Expected TLS 1.2"
  }

  assert {
    condition     = length(azurerm_storage_container.this) == 2
    error_message = "Expected 2 blob containers"
  }

  assert {
    condition     = length(azurerm_storage_share.this) == 1
    error_message = "Expected 1 file share"
  }
}
