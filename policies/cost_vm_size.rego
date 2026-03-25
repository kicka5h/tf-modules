package terraform.cost.vm_size

import rego.v1

# Restrict VM sizes in non-production environments.
# Dev/QA should use cost-effective sizes, not production-grade hardware.

# Maximum allowed VM families per environment tier.
# Production (stage/prod) has no restrictions.
# Non-production (dev/qa) restricts to smaller sizes.

dev_allowed_prefixes := {
  "Standard_B",   # burstable
  "Standard_D2",  # 2 vCPU
  "Standard_D4",  # 4 vCPU
  "Standard_E2",  # 2 vCPU memory-optimized
  "Standard_F2",  # 2 vCPU compute-optimized
  "Standard_F4",  # 4 vCPU compute-optimized
}

vm_resource_types := {
  "azurerm_linux_virtual_machine",
  "azurerm_windows_virtual_machine",
  "azurerm_linux_virtual_machine_scale_set",
  "azurerm_windows_virtual_machine_scale_set",
}

is_nonprod if {
  env := input.variables.environment.value
  env in {"dev", "qa"}
}

is_nonprod if {
  tags := input.planned_values.root_module.resources[_].values.tags
  tags.environment in {"dev", "qa"}
}

vm_size_allowed(size) if {
  some prefix in dev_allowed_prefixes
  startswith(size, prefix)
}

deny contains msg if {
  is_nonprod
  some rc in input.resource_changes
  rc.type in vm_resource_types
  "create" in rc.change.actions
  size := rc.change.after.size
  size != null
  not vm_size_allowed(size)
  msg := sprintf(
    "Cost policy: VM size '%s' on '%s' is too large for non-production. Allowed prefixes: %v",
    [size, rc.address, dev_allowed_prefixes],
  )
}

deny contains msg if {
  is_nonprod
  some rc in input.resource_changes
  rc.type in vm_resource_types
  "create" in rc.change.actions
  sku := rc.change.after.sku
  sku != null
  not vm_size_allowed(sku)
  msg := sprintf(
    "Cost policy: VMSS SKU '%s' on '%s' is too large for non-production. Allowed prefixes: %v",
    [sku, rc.address, dev_allowed_prefixes],
  )
}
