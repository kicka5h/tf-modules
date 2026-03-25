mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
}

run "reject_invalid_allocation_method" {
  command = plan

  variables {
    public_ips = {
      bad = {
        name              = "pip-bad"
        allocation_method = "Invalid"
      }
    }
  }

  expect_failures = [var.public_ips]
}

run "reject_invalid_sku" {
  command = plan

  variables {
    public_ips = {
      bad = {
        name = "pip-bad"
        sku  = "Premium"
      }
    }
  }

  expect_failures = [var.public_ips]
}

run "reject_invalid_sku_tier" {
  command = plan

  variables {
    public_ips = {
      bad = {
        name     = "pip-bad"
        sku_tier = "Galactic"
      }
    }
  }

  expect_failures = [var.public_ips]
}
