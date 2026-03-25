mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
}

run "rejects_reserved_priority" {
  command         = plan
  expect_failures = [var.nsgs]

  variables {
    nsgs = {
      bad = {
        name = "nsg-bad"
        rules = {
          invalid = {
            priority                   = 150
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "443"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
          }
        }
      }
    }
  }
}

run "rejects_invalid_direction" {
  command         = plan
  expect_failures = [var.nsgs]

  variables {
    nsgs = {
      bad = {
        name = "nsg-bad"
        rules = {
          invalid = {
            priority                   = 200
            direction                  = "InvalidDirection"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "443"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
          }
        }
      }
    }
  }
}

run "rejects_invalid_access" {
  command         = plan
  expect_failures = [var.nsgs]

  variables {
    nsgs = {
      bad = {
        name = "nsg-bad"
        rules = {
          invalid = {
            priority                   = 200
            direction                  = "Inbound"
            access                     = "InvalidAccess"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "443"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
          }
        }
      }
    }
  }
}

run "rejects_invalid_protocol" {
  command         = plan
  expect_failures = [var.nsgs]

  variables {
    nsgs = {
      bad = {
        name = "nsg-bad"
        rules = {
          invalid = {
            priority                   = 200
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "InvalidProtocol"
            source_port_range          = "*"
            destination_port_range     = "443"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
          }
        }
      }
    }
  }
}
