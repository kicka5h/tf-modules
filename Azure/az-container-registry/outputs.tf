output "container_registries" {
  description = "Map of container registries created, keyed by the logical name"
  value = {
    for k, v in azurerm_container_registry.this : k => {
      id             = v.id
      name           = v.name
      login_server   = v.login_server
      admin_username = v.admin_username
      identity = try({
        principal_id = v.identity[0].principal_id
      }, null)
    }
  }
}
