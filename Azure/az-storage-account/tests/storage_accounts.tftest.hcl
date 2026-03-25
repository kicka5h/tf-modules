mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  storage_accounts = {
    main = {
      name = "stteststoragemain"
      containers = {
        data = {
          name = "data"
        }
        logs = {
          name                  = "logs"
          container_access_type = "private"
        }
      }
      file_shares = {
        config = {
          name  = "config"
          quota = 100
        }
      }
    }
  }
}

run "creates_storage_account" {
  command = plan

  assert {
    condition     = length(azurerm_storage_account.this) == 1
    error_message = "Expected 1 storage account"
  }

  assert {
    condition     = azurerm_storage_account.this["main"].name == "stteststoragemain"
    error_message = "Expected storage account name to be stteststoragemain"
  }
}

run "sets_location_and_resource_group" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this["main"].location == "eastus2"
    error_message = "Expected location to be eastus2"
  }

  assert {
    condition     = azurerm_storage_account.this["main"].resource_group_name == "rg-test"
    error_message = "Expected resource group to be rg-test"
  }
}

run "enforces_secure_defaults" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this["main"].enable_https_traffic_only == true
    error_message = "Expected HTTPS only to be enabled"
  }

  assert {
    condition     = azurerm_storage_account.this["main"].min_tls_version == "TLS1_2"
    error_message = "Expected minimum TLS version to be TLS1_2"
  }

  assert {
    condition     = azurerm_storage_account.this["main"].allow_nested_items_to_be_public == false
    error_message = "Expected public blob access to be disabled"
  }

  assert {
    condition     = azurerm_storage_account.this["main"].shared_access_key_enabled == false
    error_message = "Expected shared access key to be disabled"
  }

  assert {
    condition     = azurerm_storage_account.this["main"].public_network_access_enabled == false
    error_message = "Expected public network access to be disabled"
  }

  assert {
    condition     = azurerm_storage_account.this["main"].infrastructure_encryption_enabled == true
    error_message = "Expected infrastructure encryption to be enabled"
  }
}

run "uses_geo_redundant_replication_by_default" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this["main"].account_replication_type == "GRS"
    error_message = "Expected default replication type to be GRS"
  }
}

run "creates_containers" {
  command = plan

  assert {
    condition     = length(azurerm_storage_container.this) == 2
    error_message = "Expected 2 containers"
  }

  assert {
    condition     = azurerm_storage_container.this["main-data"].name == "data"
    error_message = "Expected container name to be data"
  }

  assert {
    condition     = azurerm_storage_container.this["main-logs"].container_access_type == "private"
    error_message = "Expected container access type to be private"
  }
}

run "creates_file_shares" {
  command = plan

  assert {
    condition     = length(azurerm_storage_share.this) == 1
    error_message = "Expected 1 file share"
  }

  assert {
    condition     = azurerm_storage_share.this["main-config"].name == "config"
    error_message = "Expected file share name to be config"
  }

  assert {
    condition     = azurerm_storage_share.this["main-config"].quota == 100
    error_message = "Expected file share quota to be 100"
  }
}
