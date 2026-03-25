output "vpn_gateways" {
  description = "Map of VPN gateways created, keyed by the logical name"
  value = {
    for k, v in azurerm_virtual_network_gateway.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "local_network_gateways" {
  description = "Map of local network gateways created, keyed by gateway-lgw logical name"
  value = {
    for k, v in azurerm_local_network_gateway.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "connections" {
  description = "Map of VPN connections created, keyed by gateway-connection logical name"
  value = {
    for k, v in azurerm_virtual_network_gateway_connection.this : k => {
      id   = v.id
      name = v.name
    }
  }
}
