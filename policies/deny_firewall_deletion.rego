package terraform.firewall

import rego.v1

denied_resource_types := {
  "azurerm_firewall",
  "azurerm_firewall_policy",
}

# Catch resources being deleted (action: delete only)
deleted_firewalls contains rc if {
  some rc in input.resource_changes
  rc.type in denied_resource_types
  "delete" in rc.change.actions
  not "create" in rc.change.actions
}

# Catch resources being replaced (action: delete + create)
replaced_firewalls contains rc if {
  some rc in input.resource_changes
  rc.type in denied_resource_types
  "delete" in rc.change.actions
  "create" in rc.change.actions
}

deny contains msg if {
  some rc in deleted_firewalls
  msg := sprintf(
    "Deletion of %s '%s' is not allowed. Remove the resource from the plan or request an exception.",
    [rc.type, rc.address],
  )
}

deny contains msg if {
  some rc in replaced_firewalls
  msg := sprintf(
    "Replacement (delete+create) of %s '%s' is not allowed. A replacement destroys the existing resource. Adjust the change to avoid replacement or request an exception.",
    [rc.type, rc.address],
  )
}
