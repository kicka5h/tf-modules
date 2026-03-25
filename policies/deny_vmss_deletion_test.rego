package terraform.vmss

import rego.v1

# -- Helpers to build test plans --

mock_plan(resource_changes) := {"resource_changes": resource_changes}

mock_change(type, address, actions) := {
  "type": type,
  "address": address,
  "change": {"actions": actions},
}

# -- No deletions: should pass --

test_allow_create_linux_vmss if {
  plan := mock_plan([mock_change("azurerm_linux_virtual_machine_scale_set", "module.vmss.azurerm_linux_virtual_machine_scale_set.this[\"web\"]", ["create"])])
  count(deny) == 0 with input as plan
}

test_allow_create_windows_vmss if {
  plan := mock_plan([mock_change("azurerm_windows_virtual_machine_scale_set", "module.vmss.azurerm_windows_virtual_machine_scale_set.this[\"app\"]", ["create"])])
  count(deny) == 0 with input as plan
}

test_allow_update_linux_vmss if {
  plan := mock_plan([mock_change("azurerm_linux_virtual_machine_scale_set", "module.vmss.azurerm_linux_virtual_machine_scale_set.this[\"web\"]", ["update"])])
  count(deny) == 0 with input as plan
}

test_allow_no_op if {
  plan := mock_plan([mock_change("azurerm_linux_virtual_machine_scale_set", "module.vmss.azurerm_linux_virtual_machine_scale_set.this[\"web\"]", ["no-op"])])
  count(deny) == 0 with input as plan
}

# -- Deletions: should deny --

test_deny_delete_linux_vmss if {
  plan := mock_plan([mock_change("azurerm_linux_virtual_machine_scale_set", "module.vmss.azurerm_linux_virtual_machine_scale_set.this[\"web\"]", ["delete"])])
  count(deny) == 1 with input as plan
}

test_deny_delete_windows_vmss if {
  plan := mock_plan([mock_change("azurerm_windows_virtual_machine_scale_set", "module.vmss.azurerm_windows_virtual_machine_scale_set.this[\"app\"]", ["delete"])])
  count(deny) == 1 with input as plan
}

test_deny_replace_linux_vmss if {
  plan := mock_plan([mock_change("azurerm_linux_virtual_machine_scale_set", "module.vmss.azurerm_linux_virtual_machine_scale_set.this[\"web\"]", ["delete", "create"])])
  count(deny) == 1 with input as plan
}

test_deny_replace_windows_vmss if {
  plan := mock_plan([mock_change("azurerm_windows_virtual_machine_scale_set", "module.vmss.azurerm_windows_virtual_machine_scale_set.this[\"app\"]", ["delete", "create"])])
  count(deny) == 1 with input as plan
}

# -- Multiple deletions --

test_deny_multiple_deletions if {
  plan := mock_plan([
    mock_change("azurerm_linux_virtual_machine_scale_set", "module.vmss.azurerm_linux_virtual_machine_scale_set.this[\"a\"]", ["delete"]),
    mock_change("azurerm_windows_virtual_machine_scale_set", "module.vmss.azurerm_windows_virtual_machine_scale_set.this[\"b\"]", ["delete"]),
  ])
  count(deny) == 2 with input as plan
}

# -- Unrelated resources: should not trigger --

test_allow_delete_unrelated_resource if {
  plan := mock_plan([mock_change("azurerm_resource_group", "azurerm_resource_group.main", ["delete"])])
  count(deny) == 0 with input as plan
}
