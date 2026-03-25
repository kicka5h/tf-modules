mock_provider "azurerm" {}
mock_provider "http" {}

variables {
  resource_group_name = "rg-test"
}

run "rejects_invalid_sku_name" {
  command = plan

  variables {
    front_doors = {
      bad = {
        name     = "fd-bad"
        sku_name = "InvalidSku"
      }
    }
  }

  expect_failures = [var.front_doors]
}
