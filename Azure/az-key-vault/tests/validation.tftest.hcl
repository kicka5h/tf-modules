mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  key_vaults = {
    bad = {
      name                     = "kv-bad-purge"
      purge_protection_enabled = false
    }
  }
}

run "rejects_purge_protection_disabled" {
  command         = plan
  expect_failures = [var.key_vaults]
}

run "rejects_invalid_sku" {
  command         = plan
  expect_failures = [var.key_vaults]

  variables {
    key_vaults = {
      bad = {
        name     = "kv-bad-sku"
        sku_name = "basic"
      }
    }
  }
}
