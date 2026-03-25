mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  public_ips = {
    test = {
      name = "pip-test"
    }
  }
}

run "default_terraform_tag_is_applied" {
  command = plan

  assert {
    condition     = azurerm_public_ip.this["test"].tags["Terraform"] == "true"
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
    condition     = azurerm_public_ip.this["test"].tags["Terraform"] == "true"
    error_message = "Default Terraform tag should still be present"
  }

  assert {
    condition     = azurerm_public_ip.this["test"].tags["environment"] == "dev"
    error_message = "Custom tag should be present"
  }
}

run "tags_applied_to_prefix" {
  command = plan

  variables {
    public_ip_prefixes = {
      test = {
        name          = "ippre-test"
        prefix_length = 28
      }
    }
  }

  assert {
    condition     = azurerm_public_ip_prefix.this["test"].tags["Terraform"] == "true"
    error_message = "Expected default Terraform tag on prefix"
  }
}
