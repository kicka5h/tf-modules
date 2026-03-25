mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  key_vaults = {
    test = {
      name = "kv-test-tags"
    }
  }
}

run "default_terraform_tag_is_applied" {
  command = plan

  assert {
    condition     = azurerm_key_vault.this["test"].tags["Terraform"] == "true"
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
    condition     = azurerm_key_vault.this["test"].tags["Terraform"] == "true"
    error_message = "Default Terraform tag should still be present"
  }

  assert {
    condition     = azurerm_key_vault.this["test"].tags["environment"] == "dev"
    error_message = "Custom tag should be present"
  }
}

run "per_vault_tags_are_merged" {
  command = plan

  variables {
    tags = {
      environment = "dev"
    }
    key_vaults = {
      test = {
        name = "kv-test-tags"
        tags = {
          team = "platform"
        }
      }
    }
  }

  assert {
    condition     = azurerm_key_vault.this["test"].tags["Terraform"] == "true"
    error_message = "Default Terraform tag should still be present"
  }

  assert {
    condition     = azurerm_key_vault.this["test"].tags["environment"] == "dev"
    error_message = "Module-level tag should be present"
  }

  assert {
    condition     = azurerm_key_vault.this["test"].tags["team"] == "platform"
    error_message = "Per-vault tag should be present"
  }
}
