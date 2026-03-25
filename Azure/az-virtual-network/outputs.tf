output "vnets" {
  description = "Map of VNets created, keyed by the logical name"
  value = {
    for k, v in azurerm_virtual_network.this : k => {
      id            = v.id
      name          = v.name
      address_space = v.address_space
    }
  }
}

output "subnets" {
  description = "Map of subnets created, keyed by vnet-subnet logical name"
  value = {
    for k, v in azurerm_subnet.this : k => {
      id               = v.id
      name             = v.name
      address_prefixes = v.address_prefixes
    }
  }
}
