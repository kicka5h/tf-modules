mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  container_registries = {
    bad = {
      name          = "crbadregistry"
      admin_enabled = true
    }
  }
}

run "rejects_admin_enabled" {
  command         = plan
  expect_failures = [var.container_registries]
}

run "rejects_invalid_sku" {
  command         = plan
  expect_failures = [var.container_registries]

  variables {
    container_registries = {
      bad = {
        name = "crbadsku"
        sku  = "Enterprise"
      }
    }
  }
}
