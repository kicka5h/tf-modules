package terraform.appservice

import rego.v1

denied_resource_types := {
  "azurerm_service_plan",
  "azurerm_linux_web_app",
  "azurerm_windows_web_app",
}

# Catch resources being deleted (action: delete only)
deleted_resources contains rc if {
  some rc in input.resource_changes
  rc.type in denied_resource_types
  "delete" in rc.change.actions
  not "create" in rc.change.actions
}

# Catch resources being replaced (action: delete + create)
replaced_resources contains rc if {
  some rc in input.resource_changes
  rc.type in denied_resource_types
  "delete" in rc.change.actions
  "create" in rc.change.actions
}

deny contains msg if {
  some rc in deleted_resources
  msg := sprintf(
    "Deletion of %s '%s' is not allowed. Remove the resource from the plan or request an exception.",
    [rc.type, rc.address],
  )
}

deny contains msg if {
  some rc in replaced_resources
  msg := sprintf(
    "Replacement (delete+create) of %s '%s' is not allowed. A replacement destroys the existing resource. Adjust the change to avoid replacement or request an exception.",
    [rc.type, rc.address],
  )
}
