package terraform.cost.vpn_sku

import rego.v1

# Restrict VPN Gateway SKU in non-production environments.
# Higher-tier SKUs (VpnGw3+) are expensive and unnecessary for dev/qa.

dev_allowed_skus := {
  "Basic",
  "VpnGw1",
  "VpnGw1AZ",
  "VpnGw2",
  "VpnGw2AZ",
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
  rc.type == "azurerm_virtual_network_gateway"
  "create" in rc.change.actions
  sku := rc.change.after.sku
  sku != null
  not sku in dev_allowed_skus
  msg := sprintf(
    "Cost policy: VPN Gateway '%s' uses SKU '%s' in non-production. Allowed: %v",
    [rc.address, sku, dev_allowed_skus],
  )
}
