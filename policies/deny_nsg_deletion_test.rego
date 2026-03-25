package terraform.nsg

import rego.v1

# -- Helpers to build test plans --

mock_plan(resource_changes) := {"resource_changes": resource_changes}

mock_change(type, address, actions) := {
  "type": type,
  "address": address,
  "change": {"actions": actions},
}

# -- No deletions: should pass --

test_allow_create_nsg if {
  plan := mock_plan([mock_change("azurerm_network_security_group", "module.nsg.azurerm_network_security_group.this[\"web\"]", ["create"])])
  count(deny) == 0 with input as plan
}

test_allow_update_nsg if {
  plan := mock_plan([mock_change("azurerm_network_security_group", "module.nsg.azurerm_network_security_group.this[\"web\"]", ["update"])])
  count(deny) == 0 with input as plan
}

test_allow_no_op if {
  plan := mock_plan([mock_change("azurerm_network_security_group", "module.nsg.azurerm_network_security_group.this[\"web\"]", ["no-op"])])
  count(deny) == 0 with input as plan
}

# -- Deletions: should deny --

test_deny_delete_nsg if {
  plan := mock_plan([mock_change("azurerm_network_security_group", "module.nsg.azurerm_network_security_group.this[\"web\"]", ["delete"])])
  count(deny) == 1 with input as plan
}

test_deny_replace_nsg if {
  plan := mock_plan([mock_change("azurerm_network_security_group", "module.nsg.azurerm_network_security_group.this[\"web\"]", ["delete", "create"])])
  count(deny) == 1 with input as plan
}

# -- Multiple deletions --

test_deny_multiple_deletions if {
  plan := mock_plan([
    mock_change("azurerm_network_security_group", "module.nsg.azurerm_network_security_group.this[\"web\"]", ["delete"]),
    mock_change("azurerm_network_security_group", "module.nsg.azurerm_network_security_group.this[\"db\"]", ["delete"]),
  ])
  count(deny) == 2 with input as plan
}

# -- Unrelated resources: should not trigger --

test_allow_delete_unrelated_resource if {
  plan := mock_plan([mock_change("azurerm_resource_group", "azurerm_resource_group.main", ["delete"])])
  count(deny) == 0 with input as plan
}

# -- Security rules can be deleted (not protected) --

test_allow_delete_security_rule if {
  plan := mock_plan([mock_change("azurerm_network_security_rule", "module.nsg.azurerm_network_security_rule.this[\"web-allow_https\"]", ["delete"])])
  count(deny) == 0 with input as plan
}
