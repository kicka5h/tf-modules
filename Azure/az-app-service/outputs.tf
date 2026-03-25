output "service_plans" {
  description = "Map of App Service plans created, keyed by the logical name"
  value = {
    for k, v in azurerm_service_plan.this : k => {
      id      = v.id
      name    = v.name
      os_type = v.os_type
    }
  }
}

output "web_apps" {
  description = "Map of web apps created (linux + windows merged), keyed by the logical name"
  value = merge(
    {
      for k, v in azurerm_linux_web_app.this : k => {
        id                     = v.id
        name                   = v.name
        default_hostname       = v.default_hostname
        principal_id           = try(v.identity[0].principal_id, null)
        outbound_ip_addresses  = v.outbound_ip_addresses
      }
    },
    {
      for k, v in azurerm_windows_web_app.this : k => {
        id                     = v.id
        name                   = v.name
        default_hostname       = v.default_hostname
        principal_id           = try(v.identity[0].principal_id, null)
        outbound_ip_addresses  = v.outbound_ip_addresses
      }
    },
  )
}
