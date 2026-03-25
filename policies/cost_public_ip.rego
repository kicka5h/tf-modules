package terraform.cost.public_ip

import rego.v1

# Block public IP creation in non-production environments.
# Non-prod resources should be accessed via VPN, Bastion, or private endpoints.
# Production is unrestricted.

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
  rc.type == "azurerm_public_ip"
  "create" in rc.change.actions
  msg := sprintf(
    "Cost/security policy: Public IP '%s' cannot be created in non-production. Use private networking (VPN, Bastion, private endpoints) instead.",
    [rc.address],
  )
}
