output "public_dns_zones" {
  description = "Map of public DNS zones created, keyed by the logical name"
  value = {
    for k, v in azurerm_dns_zone.public : k => {
      id                = v.id
      name              = v.name
      name_servers      = v.name_servers
      number_of_record_sets = v.number_of_record_sets
    }
  }
}

output "private_dns_zones" {
  description = "Map of private DNS zones created, keyed by the logical name"
  value = {
    for k, v in azurerm_private_dns_zone.private : k => {
      id   = v.id
      name = v.name
      number_of_record_sets = v.number_of_record_sets
    }
  }
}

output "private_dns_zone_vnet_links" {
  description = "Map of private DNS zone virtual network links created"
  value = {
    for k, v in azurerm_private_dns_zone_virtual_network_link.this : k => {
      id   = v.id
      name = v.name
    }
  }
}
