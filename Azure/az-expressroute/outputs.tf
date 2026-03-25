output "expressroute_circuits" {
  description = "Map of ExpressRoute circuits created, keyed by the logical name"
  value = {
    for k, v in azurerm_express_route_circuit.this : k => {
      id                                  = v.id
      name                                = v.name
      service_provider_provisioning_state = v.service_provider_provisioning_state
      service_key                         = v.service_key
    }
  }
  sensitive = true
}

output "peerings" {
  description = "Map of ExpressRoute circuit peerings created, keyed by circuit-peering logical name"
  value = {
    for k, v in azurerm_express_route_circuit_peering.this : k => {
      id                   = v.id
      peering_type         = v.peering_type
      azure_asn            = v.azure_asn
      primary_azure_port   = v.primary_azure_port
      secondary_azure_port = v.secondary_azure_port
    }
  }
}
