mock_provider "azurerm" {}

variables {
  root_cidrs = ["10.0.0.0/8"]

  # Reserve a range that overlaps with the dev allocation
  reserved_cidrs = [
    "10.0.0.0/16",
    "172.16.0.0/12",
  ]

  allocations = {
    dev = {
      cidr_newbits = 8
      cidr_index   = 0   # This would be 10.0.0.0/16 — overlaps with reserved
      vnets = {
        hub = {
          cidr_newbits = 4
          cidr_index   = 0
          subnets = {
            gateway = { cidr_newbits = 4, cidr_index = 0 }
          }
        }
      }
    }
  }
}

run "detects_overlap_with_reserved" {
  command = plan

  assert {
    condition     = output.has_overlaps == true
    error_message = "Expected overlap to be detected with reserved CIDR 10.0.0.0/16"
  }

  assert {
    condition     = length(output.overlapping_cidrs) > 0
    error_message = "Expected at least one overlapping CIDR pair"
  }
}
