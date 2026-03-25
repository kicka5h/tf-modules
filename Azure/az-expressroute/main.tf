locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)

  # Flatten peerings into a map for for_each
  peerings = {
    for item in flatten([
      for circuit_key, circuit in var.expressroute_circuits : [
        for peering_key, peering in circuit.peerings : {
          key                           = "${circuit_key}-${peering_key}"
          circuit_key                   = circuit_key
          peering_type                  = peering.peering_type
          vlan_id                       = peering.vlan_id
          primary_peer_address_prefix   = peering.primary_peer_address_prefix
          secondary_peer_address_prefix = peering.secondary_peer_address_prefix
          peer_asn                      = peering.peer_asn
          shared_key                    = peering.shared_key
          microsoft_peering_config      = peering.microsoft_peering_config
        }
      ]
    ]) : item.key => item
  }
}

resource "azurerm_express_route_circuit" "this" {
  for_each = var.expressroute_circuits

  name                     = each.value.name
  location                 = var.location
  resource_group_name      = var.resource_group_name
  service_provider_name    = each.value.service_provider_name
  peering_location         = each.value.peering_location
  bandwidth_in_mbps        = each.value.bandwidth_in_mbps
  allow_classic_operations = each.value.allow_classic_operations
  tags                     = local.tags

  sku {
    tier   = each.value.sku.tier
    family = each.value.sku.family
  }
}

resource "azurerm_express_route_circuit_peering" "this" {
  for_each = local.peerings

  peering_type                  = each.value.peering_type
  express_route_circuit_name    = azurerm_express_route_circuit.this[each.value.circuit_key].name
  resource_group_name           = var.resource_group_name
  vlan_id                       = each.value.vlan_id
  primary_peer_address_prefix   = each.value.primary_peer_address_prefix
  secondary_peer_address_prefix = each.value.secondary_peer_address_prefix
  peer_asn                      = each.value.peer_asn
  shared_key                    = each.value.shared_key

  dynamic "microsoft_peering_config" {
    for_each = each.value.microsoft_peering_config != null ? [each.value.microsoft_peering_config] : []
    content {
      advertised_public_prefixes = microsoft_peering_config.value.advertised_public_prefixes
    }
  }
}
