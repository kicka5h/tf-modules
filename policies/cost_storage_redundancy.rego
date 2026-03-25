package terraform.cost.storage_redundancy

import rego.v1

# Restrict storage redundancy in non-production environments.
# Dev/QA should use LRS (locally redundant), not GRS/GZRS/RA-GRS.

expensive_replication_types := {
  "GRS",
  "GZRS",
  "RAGRS",
  "RAGZRS",
}

is_nonprod if {
  env := input.variables.environment.value
  env in {"dev", "qa"}
}

is_nonprod if {
  tags := input.planned_values.root_module.resources[_].values.tags
  tags.environment in {"dev", "qa"}
}

deny contains msg if {
  is_nonprod
  some rc in input.resource_changes
  rc.type == "azurerm_storage_account"
  "create" in rc.change.actions
  repl := rc.change.after.account_replication_type
  repl in expensive_replication_types
  msg := sprintf(
    "Cost policy: Storage account '%s' uses '%s' replication in non-production. Use 'LRS' or 'ZRS' instead.",
    [rc.address, repl],
  )
}
