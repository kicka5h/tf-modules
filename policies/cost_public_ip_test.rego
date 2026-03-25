package terraform.cost.public_ip

import rego.v1

mock_plan(env, count) := {
  "variables": {"environment": {"value": env}},
  "planned_values": {"root_module": {"resources": []}},
  "resource_changes": [
    {
      "type": "azurerm_public_ip",
      "address": sprintf("module.pips.azurerm_public_ip.this[\"%d\"]", [i]),
      "change": {"actions": ["create"], "after": {}},
    } |
    i := numbers.range(0, count - 1)[_]
  ],
}

test_deny_any_public_ip_in_dev if {
  count(deny) == 1 with input as mock_plan("dev", 1)
}

test_deny_multiple_public_ips_in_qa if {
  count(deny) == 3 with input as mock_plan("qa", 3)
}

test_allow_public_ip_in_prod if {
  count(deny) == 0 with input as mock_plan("prod", 5)
}

test_allow_public_ip_in_stage if {
  count(deny) == 0 with input as mock_plan("stage", 3)
}

test_no_deny_when_no_public_ips if {
  plan := {
    "variables": {"environment": {"value": "dev"}},
    "planned_values": {"root_module": {"resources": []}},
    "resource_changes": [],
  }
  count(deny) == 0 with input as plan
}
