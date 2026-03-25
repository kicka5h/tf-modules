package terraform.cost.vm_size

import rego.v1

mock_plan(env, resource_type, size_field, size_value) := {
  "variables": {"environment": {"value": env}},
  "planned_values": {"root_module": {"resources": []}},
  "resource_changes": [{
    "type": resource_type,
    "address": "module.vm.azurerm_linux_virtual_machine.this[\"test\"]",
    "change": {
      "actions": ["create"],
      "after": object.union(
        {"size": null, "sku": null},
        {size_field: size_value},
      ),
    },
  }],
}

test_allow_small_vm_in_dev if {
  plan := mock_plan("dev", "azurerm_linux_virtual_machine", "size", "Standard_B2s")
  count(deny) == 0 with input as plan
}

test_deny_large_vm_in_dev if {
  plan := mock_plan("dev", "azurerm_linux_virtual_machine", "size", "Standard_D16s_v5")
  count(deny) == 1 with input as plan
}

test_allow_large_vm_in_prod if {
  plan := mock_plan("prod", "azurerm_linux_virtual_machine", "size", "Standard_D16s_v5")
  count(deny) == 0 with input as plan
}

test_deny_large_vmss_in_qa if {
  plan := mock_plan("qa", "azurerm_linux_virtual_machine_scale_set", "sku", "Standard_E32s_v5")
  count(deny) == 1 with input as plan
}

test_allow_d4_vm_in_dev if {
  plan := mock_plan("dev", "azurerm_windows_virtual_machine", "size", "Standard_D4s_v5")
  count(deny) == 0 with input as plan
}
