output "private_endpoints" {
  description = "Map of private endpoints created, keyed by the logical name"
  value = {
    for k, v in azurerm_private_endpoint.this : k => {
      id                 = v.id
      name               = v.name
      private_ip_address = v.private_service_connection[0].private_ip_address
      custom_dns_configs = v.custom_dns_configs
    }
  }
}
