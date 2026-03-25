mock_provider "azurerm" {}

variables {
  root_cidrs = ["10.0.0.0/8"]

  allocations = {
    dev = {
      cidr_newbits = 8
      cidr_index   = 0
      vnets = {
        hub = {
          cidr_newbits = 4
          cidr_index   = 0
          subnets = {
            gateway  = { cidr_newbits = 4, cidr_index = 0 }
            firewall = { cidr_newbits = 4, cidr_index = 1 }
          }
        }
        spoke1 = {
          cidr_newbits = 4
          cidr_index   = 1
          subnets = {
            app  = { cidr_newbits = 2, cidr_index = 0 }
            data = { cidr_newbits = 4, cidr_index = 2 }
          }
        }
      }
    }
    prod = {
      cidr_newbits = 8
      cidr_index   = 1
      vnets = {
        hub = {
          cidr_newbits = 4
          cidr_index   = 0
          subnets = {
            gateway    = { cidr_newbits = 4, cidr_index = 0 }
            firewall   = { cidr_newbits = 4, cidr_index = 1 }
            management = { cidr_newbits = 4, cidr_index = 2 }
          }
        }
      }
    }
  }
}

run "environment_cidrs_are_correct" {
  command = plan

  assert {
    condition     = output.environment_cidrs["dev"] == "10.0.0.0/16"
    error_message = "Expected dev environment CIDR to be 10.0.0.0/16"
  }

  assert {
    condition     = output.environment_cidrs["prod"] == "10.1.0.0/16"
    error_message = "Expected prod environment CIDR to be 10.1.0.0/16"
  }
}

run "vnet_cidrs_are_correct" {
  command = plan

  assert {
    condition     = output.vnet_cidrs["dev-hub"].cidr == "10.0.0.0/20"
    error_message = "Expected dev-hub VNet CIDR to be 10.0.0.0/20"
  }

  assert {
    condition     = output.vnet_cidrs["dev-spoke1"].cidr == "10.0.16.0/20"
    error_message = "Expected dev-spoke1 VNet CIDR to be 10.0.16.0/20"
  }

  assert {
    condition     = output.vnet_cidrs["prod-hub"].cidr == "10.1.0.0/20"
    error_message = "Expected prod-hub VNet CIDR to be 10.1.0.0/20"
  }
}

run "subnet_cidrs_are_correct" {
  command = plan

  assert {
    condition     = output.subnet_cidrs["dev-hub-gateway"].cidr == "10.0.0.0/24"
    error_message = "Expected dev-hub-gateway subnet CIDR to be 10.0.0.0/24"
  }

  assert {
    condition     = output.subnet_cidrs["dev-hub-firewall"].cidr == "10.0.1.0/24"
    error_message = "Expected dev-hub-firewall subnet CIDR to be 10.0.1.0/24"
  }

  assert {
    condition     = output.subnet_cidrs["dev-spoke1-app"].cidr == "10.0.16.0/22"
    error_message = "Expected dev-spoke1-app subnet CIDR to be 10.0.16.0/22"
  }
}

run "no_overlaps_with_empty_reserved" {
  command = plan

  assert {
    condition     = output.has_overlaps == false
    error_message = "Expected no overlaps with empty reserved list"
  }
}

run "correct_counts" {
  command = plan

  assert {
    condition     = output.summary.total_vnets == 3
    error_message = "Expected 3 total VNets"
  }

  assert {
    condition     = output.summary.total_subnets == 5
    error_message = "Expected 5 total subnets"
  }
}
