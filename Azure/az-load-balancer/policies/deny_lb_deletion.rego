package terraform.lb

import rego.v1

denied_resource_types := {
  "azurerm_lb",
}

# Catch resources being deleted (action: delete only)
deleted_lbs contains rc if {
  some rc in input.resource_changes
  rc.type in denied_resource_types
  "delete" in rc.change.actions
  not "create" in rc.change.actions
}

# Catch resources being replaced (action: delete + create)
replaced_lbs contains rc if {
  some rc in input.resource_changes
  rc.type in denied_resource_types
  "delete" in rc.change.actions
  "create" in rc.change.actions
}

deny contains msg if {
  some rc in deleted_lbs
  msg := sprintf(
    "Deletion of %s '%s' is not allowed. Remove the load balancer from the plan or request an exception.",
    [rc.type, rc.address],
  )
}

deny contains msg if {
  some rc in replaced_lbs
  msg := sprintf(
    "Replacement (delete+create) of %s '%s' is not allowed. A replacement destroys the existing load balancer. Adjust the change to avoid replacement or request an exception.",
    [rc.type, rc.address],
  )
}
