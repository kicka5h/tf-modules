package terraform.storage

import rego.v1

# -- Helpers to build test plans --

mock_plan(resource_changes) := {"resource_changes": resource_changes}

mock_change(type, address, actions) := {
  "type": type,
  "address": address,
  "change": {"actions": actions},
}

# -- No deletions: should pass --

test_allow_create_storage_account if {
  plan := mock_plan([mock_change("azurerm_storage_account", "module.storage.azurerm_storage_account.this[\"main\"]", ["create"])])
  count(deny) == 0 with input as plan
}

test_allow_update_storage_account if {
  plan := mock_plan([mock_change("azurerm_storage_account", "module.storage.azurerm_storage_account.this[\"main\"]", ["update"])])
  count(deny) == 0 with input as plan
}

test_allow_no_op if {
  plan := mock_plan([mock_change("azurerm_storage_account", "module.storage.azurerm_storage_account.this[\"main\"]", ["no-op"])])
  count(deny) == 0 with input as plan
}

# -- Deletions: should deny --

test_deny_delete_storage_account if {
  plan := mock_plan([mock_change("azurerm_storage_account", "module.storage.azurerm_storage_account.this[\"main\"]", ["delete"])])
  count(deny) == 1 with input as plan
}

test_deny_replace_storage_account if {
  plan := mock_plan([mock_change("azurerm_storage_account", "module.storage.azurerm_storage_account.this[\"main\"]", ["delete", "create"])])
  count(deny) == 1 with input as plan
}

# -- Multiple deletions --

test_deny_multiple_deletions if {
  plan := mock_plan([
    mock_change("azurerm_storage_account", "module.storage.azurerm_storage_account.this[\"a\"]", ["delete"]),
    mock_change("azurerm_storage_account", "module.storage.azurerm_storage_account.this[\"b\"]", ["delete"]),
  ])
  count(deny) == 2 with input as plan
}

# -- Unrelated resources: should not trigger --

test_allow_delete_unrelated_resource if {
  plan := mock_plan([mock_change("azurerm_resource_group", "azurerm_resource_group.main", ["delete"])])
  count(deny) == 0 with input as plan
}
