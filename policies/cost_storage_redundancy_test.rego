package terraform.cost.storage_redundancy

import rego.v1

mock_plan(env, repl_type) := {
  "variables": {"environment": {"value": env}},
  "planned_values": {"root_module": {"resources": []}},
  "resource_changes": [{
    "type": "azurerm_storage_account",
    "address": "module.storage.azurerm_storage_account.this[\"test\"]",
    "change": {
      "actions": ["create"],
      "after": {"account_replication_type": repl_type},
    },
  }],
}

test_deny_grs_in_dev if {
  count(deny) == 1 with input as mock_plan("dev", "GRS")
}

test_deny_ragzrs_in_qa if {
  count(deny) == 1 with input as mock_plan("qa", "RAGZRS")
}

test_allow_lrs_in_dev if {
  count(deny) == 0 with input as mock_plan("dev", "LRS")
}

test_allow_zrs_in_dev if {
  count(deny) == 0 with input as mock_plan("dev", "ZRS")
}

test_allow_grs_in_prod if {
  count(deny) == 0 with input as mock_plan("prod", "GRS")
}

test_allow_grs_in_stage if {
  count(deny) == 0 with input as mock_plan("stage", "GRS")
}
