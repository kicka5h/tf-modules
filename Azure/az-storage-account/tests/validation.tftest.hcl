mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  storage_accounts = {
    bad = {
      name            = "stbadstorage"
      min_tls_version = "TLS1_0"
    }
  }
}

run "rejects_tls_below_1_2" {
  command         = plan
  expect_failures = [var.storage_accounts]
}

run "rejects_https_disabled" {
  command         = plan
  expect_failures = [var.storage_accounts]

  variables {
    storage_accounts = {
      bad = {
        name                      = "stbadstorage"
        enable_https_traffic_only = false
      }
    }
  }
}
