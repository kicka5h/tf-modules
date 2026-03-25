package terraform.routetable

import rego.v1

denied_resource_types := {
  "azurerm_route_table",
  "azurerm_route",
}

deny contains msg if {
  some rc in input.resource_changes
  rc.type in denied_resource_types
  "delete" in rc.change.actions
  not "create" in rc.change.actions
  msg := sprintf("Deletion of %s '%s' is not allowed.", [rc.type, rc.address])
}

deny contains msg if {
  some rc in input.resource_changes
  rc.type in denied_resource_types
  "delete" in rc.change.actions
  "create" in rc.change.actions
  msg := sprintf("Replacement (delete+create) of %s '%s' is not allowed.", [rc.type, rc.address])
}
