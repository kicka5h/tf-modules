package terraform.vpn

import rego.v1

# -- Helpers to build test plans --

mock_plan(resource_changes) := {"resource_changes": resource_changes}

mock_change(type, address, actions) := {
  "type": type,
  "address": address,
  "change": {"actions": actions},
}

# -- No deletions: should pass --

test_allow_create_gateway if {
  plan := mock_plan([mock_change("azurerm_virtual_network_gateway", "module.vpn.azurerm_virtual_network_gateway.this[\"hub\"]", ["create"])])
  count(deny) == 0 with input as plan
}

test_allow_create_connection if {
  plan := mock_plan([mock_change("azurerm_virtual_network_gateway_connection", "module.vpn.azurerm_virtual_network_gateway_connection.this[\"hub-to_dc1\"]", ["create"])])
  count(deny) == 0 with input as plan
}

test_allow_update_gateway if {
  plan := mock_plan([mock_change("azurerm_virtual_network_gateway", "module.vpn.azurerm_virtual_network_gateway.this[\"hub\"]", ["update"])])
  count(deny) == 0 with input as plan
}

test_allow_no_op if {
  plan := mock_plan([mock_change("azurerm_virtual_network_gateway", "module.vpn.azurerm_virtual_network_gateway.this[\"hub\"]", ["no-op"])])
  count(deny) == 0 with input as plan
}

# -- Deletions: should deny --

test_deny_delete_gateway if {
  plan := mock_plan([mock_change("azurerm_virtual_network_gateway", "module.vpn.azurerm_virtual_network_gateway.this[\"hub\"]", ["delete"])])
  count(deny) == 1 with input as plan
}

test_deny_delete_connection if {
  plan := mock_plan([mock_change("azurerm_virtual_network_gateway_connection", "module.vpn.azurerm_virtual_network_gateway_connection.this[\"hub-to_dc1\"]", ["delete"])])
  count(deny) == 1 with input as plan
}

test_deny_replace_gateway if {
  plan := mock_plan([mock_change("azurerm_virtual_network_gateway", "module.vpn.azurerm_virtual_network_gateway.this[\"hub\"]", ["delete", "create"])])
  count(deny) == 1 with input as plan
}

test_deny_replace_connection if {
  plan := mock_plan([mock_change("azurerm_virtual_network_gateway_connection", "module.vpn.azurerm_virtual_network_gateway_connection.this[\"hub-to_dc1\"]", ["delete", "create"])])
  count(deny) == 1 with input as plan
}

# -- Multiple deletions --

test_deny_multiple_deletions if {
  plan := mock_plan([
    mock_change("azurerm_virtual_network_gateway", "module.vpn.azurerm_virtual_network_gateway.this[\"hub\"]", ["delete"]),
    mock_change("azurerm_virtual_network_gateway_connection", "module.vpn.azurerm_virtual_network_gateway_connection.this[\"hub-to_dc1\"]", ["delete"]),
  ])
  count(deny) == 2 with input as plan
}

# -- Unrelated resources: should not trigger --

test_allow_delete_unrelated_resource if {
  plan := mock_plan([mock_change("azurerm_resource_group", "azurerm_resource_group.main", ["delete"])])
  count(deny) == 0 with input as plan
}
