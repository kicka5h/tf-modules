package terraform.cost.disk_type

import rego.v1

# Restrict disk types in non-production environments.
# Dev/QA should use Standard_LRS or StandardSSD_LRS, not Premium_LRS or UltraSSD_LRS.

expensive_disk_types := {
  "Premium_LRS",
  "Premium_ZRS",
  "UltraSSD_LRS",
}

is_nonprod if {
  env := input.variables.environment.value
  env in {"dev", "qa"}
}

is_nonprod if {
  tags := input.planned_values.root_module.resources[_].values.tags
  tags.environment in {"dev", "qa"}
}

# Managed disks
deny contains msg if {
  is_nonprod
  some rc in input.resource_changes
  rc.type == "azurerm_managed_disk"
  "create" in rc.change.actions
  rc.change.after.storage_account_type in expensive_disk_types
  msg := sprintf(
    "Cost policy: Managed disk '%s' uses '%s' in non-production. Use StandardSSD_LRS or Standard_LRS instead.",
    [rc.address, rc.change.after.storage_account_type],
  )
}

# OS disks on VMs
deny contains msg if {
  is_nonprod
  some rc in input.resource_changes
  rc.type in {"azurerm_linux_virtual_machine", "azurerm_windows_virtual_machine"}
  "create" in rc.change.actions
  some disk in rc.change.after.os_disk
  disk.storage_account_type in expensive_disk_types
  msg := sprintf(
    "Cost policy: VM '%s' OS disk uses '%s' in non-production. Use StandardSSD_LRS instead.",
    [rc.address, disk.storage_account_type],
  )
}
