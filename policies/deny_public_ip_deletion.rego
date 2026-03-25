package terraform.public_ip

import rego.v1

denied_resource_types := {
  "azurerm_public_ip",
  "azurerm_public_ip_prefix",
}

# Catch resources being deleted (action: delete only)
deleted_ips contains rc if {
  some rc in input.resource_changes
  rc.type in denied_resource_types
  "delete" in rc.change.actions
  not "create" in rc.change.actions
}

# Catch resources being replaced (action: delete + create)
replaced_ips contains rc if {
  some rc in input.resource_changes
  rc.type in denied_resource_types
  "delete" in rc.change.actions
  "create" in rc.change.actions
}

deny contains msg if {
  some rc in deleted_ips
  msg := sprintf(
    "Deletion of %s '%s' is not allowed. Remove the resource from the plan or request an exception.",
    [rc.type, rc.address],
  )
}

deny contains msg if {
  some rc in replaced_ips
  msg := sprintf(
    "Replacement (delete+create) of %s '%s' is not allowed. A replacement destroys the existing resource. Adjust the change to avoid replacement or request an exception.",
    [rc.type, rc.address],
  )
}
