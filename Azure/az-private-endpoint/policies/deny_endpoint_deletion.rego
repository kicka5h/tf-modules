package terraform.private_endpoint

import rego.v1

denied_resource_types := {
  "azurerm_private_endpoint",
}

# Catch resources being deleted (action: delete only)
deleted_endpoints contains rc if {
  some rc in input.resource_changes
  rc.type in denied_resource_types
  "delete" in rc.change.actions
  not "create" in rc.change.actions
}

# Catch resources being replaced (action: delete + create)
replaced_endpoints contains rc if {
  some rc in input.resource_changes
  rc.type in denied_resource_types
  "delete" in rc.change.actions
  "create" in rc.change.actions
}

deny contains msg if {
  some rc in deleted_endpoints
  msg := sprintf(
    "Deletion of %s '%s' is not allowed. Remove the endpoint from the plan or request an exception.",
    [rc.type, rc.address],
  )
}

deny contains msg if {
  some rc in replaced_endpoints
  msg := sprintf(
    "Replacement (delete+create) of %s '%s' is not allowed. A replacement destroys the existing endpoint. Adjust the change to avoid replacement or request an exception.",
    [rc.type, rc.address],
  )
}
