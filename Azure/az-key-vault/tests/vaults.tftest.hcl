mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  key_vaults = {
    rbac_vault = {
      name                      = "kv-test-rbac"
      enable_rbac_authorization = true
    }
    policy_vault = {
      name                      = "kv-test-policy"
      enable_rbac_authorization = false
      access_policies = {
        admin = {
          object_id          = "00000000-0000-0000-0000-000000000001"
          key_permissions    = ["Get", "List", "Create"]
          secret_permissions = ["Get", "List", "Set"]
        }
      }
    }
  }
}

run "creates_two_vaults" {
  command = plan

  assert {
    condition     = length(azurerm_key_vault.this) == 2
    error_message = "Expected 2 key vaults"
  }
}

run "rbac_vault_name_and_defaults" {
  command = plan

  assert {
    condition     = azurerm_key_vault.this["rbac_vault"].name == "kv-test-rbac"
    error_message = "Expected vault name to be kv-test-rbac"
  }

  assert {
    condition     = azurerm_key_vault.this["rbac_vault"].sku_name == "premium"
    error_message = "Expected default SKU to be premium"
  }

  assert {
    condition     = azurerm_key_vault.this["rbac_vault"].purge_protection_enabled == true
    error_message = "Expected purge protection to be enabled"
  }

  assert {
    condition     = azurerm_key_vault.this["rbac_vault"].enable_rbac_authorization == true
    error_message = "Expected RBAC authorization to be enabled"
  }

  assert {
    condition     = azurerm_key_vault.this["rbac_vault"].public_network_access_enabled == false
    error_message = "Expected public network access to be disabled"
  }

  assert {
    condition     = azurerm_key_vault.this["rbac_vault"].soft_delete_retention_days == 90
    error_message = "Expected soft delete retention to be 90 days"
  }

  assert {
    condition     = azurerm_key_vault.this["rbac_vault"].enabled_for_deployment == true
    error_message = "Expected enabled_for_deployment to be true"
  }

  assert {
    condition     = azurerm_key_vault.this["rbac_vault"].enabled_for_disk_encryption == true
    error_message = "Expected enabled_for_disk_encryption to be true"
  }

  assert {
    condition     = azurerm_key_vault.this["rbac_vault"].enabled_for_template_deployment == true
    error_message = "Expected enabled_for_template_deployment to be true"
  }
}

run "sets_location_and_resource_group" {
  command = plan

  assert {
    condition     = azurerm_key_vault.this["rbac_vault"].location == "eastus2"
    error_message = "Expected location to be eastus2"
  }

  assert {
    condition     = azurerm_key_vault.this["rbac_vault"].resource_group_name == "rg-test"
    error_message = "Expected resource group to be rg-test"
  }
}

run "policy_vault_has_access_policy" {
  command = plan

  assert {
    condition     = azurerm_key_vault.this["policy_vault"].enable_rbac_authorization == false
    error_message = "Expected RBAC authorization to be disabled on policy vault"
  }

  assert {
    condition     = length(azurerm_key_vault_access_policy.this) == 1
    error_message = "Expected 1 access policy"
  }

  assert {
    condition     = azurerm_key_vault_access_policy.this["policy_vault-admin"].object_id == "00000000-0000-0000-0000-000000000001"
    error_message = "Expected access policy object_id to match"
  }
}

run "rbac_vault_has_no_access_policies" {
  command = plan

  # The only access policy should be from the policy_vault, not the rbac_vault
  assert {
    condition     = !contains(keys(azurerm_key_vault_access_policy.this), "rbac_vault-admin")
    error_message = "Expected no access policies for RBAC vault"
  }
}
