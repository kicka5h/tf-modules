package terraform.keyvault

import rego.v1

denied_resource_types := {
  "azurerm_key_vault",
}

# Catch resources being deleted (action: delete only)
deleted_vaults contains rc if {
  some rc in input.resource_changes
  rc.type in denied_resource_types
  "delete" in rc.change.actions
  not "create" in rc.change.actions
}

# Catch resources being replaced (action: delete + create)
replaced_vaults contains rc if {
  some rc in input.resource_changes
  rc.type in denied_resource_types
  "delete" in rc.change.actions
  "create" in rc.change.actions
}

deny contains msg if {
  some rc in deleted_vaults
  msg := sprintf(
    "CRITICAL: Deletion of %s '%s' is not allowed. Purge protection causes a 90-day lockout of the vault name. Remove the vault from the plan or request an exception.",
    [rc.type, rc.address],
  )
}

deny contains msg if {
  some rc in replaced_vaults
  msg := sprintf(
    "CRITICAL: Replacement (delete+create) of %s '%s' is not allowed. A replacement destroys the existing vault and purge protection causes a 90-day lockout of the vault name. Adjust the change to avoid replacement or request an exception.",
    [rc.type, rc.address],
  )
}
