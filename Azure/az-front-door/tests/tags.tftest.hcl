mock_provider "azurerm" {}
mock_provider "http" {}

variables {
  resource_group_name = "rg-test"

  front_doors = {
    test = {
      name     = "fd-test"
      sku_name = "Standard_AzureFrontDoor"
      endpoints = {
        main = {
          name = "fd-test-main"
        }
      }
      origin_groups = {}
      routes        = {}
    }
  }
}

run "default_terraform_tag_is_applied" {
  command = plan

  assert {
    condition     = azurerm_cdn_frontdoor_profile.this["test"].tags["Terraform"] == "true"
    error_message = "Expected default Terraform tag"
  }
}

run "custom_tags_are_merged" {
  command = plan

  variables {
    tags = {
      environment = "dev"
    }
  }

  assert {
    condition     = azurerm_cdn_frontdoor_profile.this["test"].tags["Terraform"] == "true"
    error_message = "Default Terraform tag should still be present"
  }

  assert {
    condition     = azurerm_cdn_frontdoor_profile.this["test"].tags["environment"] == "dev"
    error_message = "Custom tag should be present"
  }
}
