package terraform.firewall

import rego.v1

# -- Helpers to build test plans --

mock_plan(resource_changes) := {"resource_changes": resource_changes}

mock_change(type, address, actions) := {
  "type": type,
  "address": address,
  "change": {"actions": actions},
}

# -- No deletions: should pass --

test_allow_create_firewall if {
  plan := mock_plan([mock_change("azurerm_firewall", "module.fw.azurerm_firewall.this[\"hub\"]", ["create"])])
  count(deny) == 0 with input as plan
}

test_allow_create_firewall_policy if {
  plan := mock_plan([mock_change("azurerm_firewall_policy", "module.fw.azurerm_firewall_policy.this[\"hub\"]", ["create"])])
  count(deny) == 0 with input as plan
}

test_allow_update_firewall if {
  plan := mock_plan([mock_change("azurerm_firewall", "module.fw.azurerm_firewall.this[\"hub\"]", ["update"])])
  count(deny) == 0 with input as plan
}

test_allow_no_op if {
  plan := mock_plan([mock_change("azurerm_firewall", "module.fw.azurerm_firewall.this[\"hub\"]", ["no-op"])])
  count(deny) == 0 with input as plan
}

# -- Deletions: should deny --

test_deny_delete_firewall if {
  plan := mock_plan([mock_change("azurerm_firewall", "module.fw.azurerm_firewall.this[\"hub\"]", ["delete"])])
  count(deny) == 1 with input as plan
}

test_deny_delete_firewall_policy if {
  plan := mock_plan([mock_change("azurerm_firewall_policy", "module.fw.azurerm_firewall_policy.this[\"hub\"]", ["delete"])])
  count(deny) == 1 with input as plan
}

test_deny_replace_firewall if {
  plan := mock_plan([mock_change("azurerm_firewall", "module.fw.azurerm_firewall.this[\"hub\"]", ["delete", "create"])])
  count(deny) == 1 with input as plan
}

test_deny_replace_firewall_policy if {
  plan := mock_plan([mock_change("azurerm_firewall_policy", "module.fw.azurerm_firewall_policy.this[\"hub\"]", ["delete", "create"])])
  count(deny) == 1 with input as plan
}

# -- Multiple deletions --

test_deny_multiple_deletions if {
  plan := mock_plan([
    mock_change("azurerm_firewall", "module.fw.azurerm_firewall.this[\"a\"]", ["delete"]),
    mock_change("azurerm_firewall_policy", "module.fw.azurerm_firewall_policy.this[\"b\"]", ["delete"]),
  ])
  count(deny) == 2 with input as plan
}

# -- Unrelated resources: should not trigger --

test_allow_delete_unrelated_resource if {
  plan := mock_plan([mock_change("azurerm_resource_group", "azurerm_resource_group.main", ["delete"])])
  count(deny) == 0 with input as plan
}
