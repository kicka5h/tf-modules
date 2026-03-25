output "container_groups" {
  description = "Map of container groups with id, name, ip_address, and fqdn"
  value = {
    for k, cg in azurerm_container_group.this : k => {
      id         = cg.id
      name       = cg.name
      ip_address = cg.ip_address
      fqdn       = cg.fqdn
    }
  }
}
