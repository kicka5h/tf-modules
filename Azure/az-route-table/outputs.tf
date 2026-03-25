output "route_tables" {
  description = "Map of route tables created, keyed by the logical name"
  value = {
    for k, v in azurerm_route_table.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "routes" {
  description = "Map of routes created, keyed by routetable-route logical name"
  value = {
    for k, v in azurerm_route.this : k => {
      id             = v.id
      name           = v.name
      address_prefix = v.address_prefix
      next_hop_type  = v.next_hop_type
    }
  }
}

output "subnet_associations" {
  description = "Map of subnet-to-route-table associations created"
  value = {
    for k, v in azurerm_subnet_route_table_association.this : k => {
      id        = v.id
      subnet_id = v.subnet_id
    }
  }
}
