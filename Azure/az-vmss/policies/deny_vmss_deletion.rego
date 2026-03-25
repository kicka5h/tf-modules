package terraform.vmss

import rego.v1

denied_resource_types := {
  "azurerm_linux_virtual_machine_scale_set",
  "azurerm_windows_virtual_machine_scale_set",
}

# Catch resources being deleted (action: delete only)
deleted_vmss contains rc if {
  some rc in input.resource_changes
  rc.type in denied_resource_types
  "delete" in rc.change.actions
  not "create" in rc.change.actions
}

# Catch resources being replaced (action: delete + create)
replaced_vmss contains rc if {
  some rc in input.resource_changes
  rc.type in denied_resource_types
  "delete" in rc.change.actions
  "create" in rc.change.actions
}

deny contains msg if {
  some rc in deleted_vmss
  msg := sprintf(
    "Deletion of %s '%s' is not allowed. Remove the scale set from the plan or request an exception.",
    [rc.type, rc.address],
  )
}

deny contains msg if {
  some rc in replaced_vmss
  msg := sprintf(
    "Replacement (delete+create) of %s '%s' is not allowed. A replacement destroys the existing scale set. Adjust the change to avoid replacement or request an exception.",
    [rc.type, rc.address],
  )
}
