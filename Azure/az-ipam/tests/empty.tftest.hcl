mock_provider "azurerm" {}

variables {
  root_cidrs  = ["10.0.0.0/8"]
  allocations = {}
}

run "empty_allocations_produce_empty_outputs" {
  command = plan

  assert {
    condition     = length(output.environment_cidrs) == 0
    error_message = "Expected no environment CIDRs"
  }

  assert {
    condition     = length(output.vnet_cidrs) == 0
    error_message = "Expected no VNet CIDRs"
  }

  assert {
    condition     = length(output.subnet_cidrs) == 0
    error_message = "Expected no subnet CIDRs"
  }

  assert {
    condition     = output.has_overlaps == false
    error_message = "Expected no overlaps"
  }
}
