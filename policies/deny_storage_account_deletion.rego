package terraform.storage

import rego.v1

denied_resource_types := {
  "azurerm_storage_account",
}

# Catch resources being deleted (action: delete only)
deleted_accounts contains rc if {
  some rc in input.resource_changes
  rc.type in denied_resource_types
  "delete" in rc.change.actions
  not "create" in rc.change.actions
}

# Catch resources being replaced (action: delete + create)
replaced_accounts contains rc if {
  some rc in input.resource_changes
  rc.type in denied_resource_types
  "delete" in rc.change.actions
  "create" in rc.change.actions
}

deny contains msg if {
  some rc in deleted_accounts
  msg := sprintf(
    "Deletion of %s '%s' is not allowed. Remove the storage account from the plan or request an exception.",
    [rc.type, rc.address],
  )
}

deny contains msg if {
  some rc in replaced_accounts
  msg := sprintf(
    "Replacement (delete+create) of %s '%s' is not allowed. A replacement destroys the existing storage account. Adjust the change to avoid replacement or request an exception.",
    [rc.type, rc.address],
  )
}
