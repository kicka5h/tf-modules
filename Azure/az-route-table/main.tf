locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)

  # Flatten routes into a map for for_each
  routes = {
    for item in flatten([
      for rt_key, rt in var.route_tables : [
        for route_key, route in rt.routes : {
          key                    = "${rt_key}-${route_key}"
          rt_key                 = rt_key
          name                   = route_key
          address_prefix         = route.address_prefix
          next_hop_type          = route.next_hop_type
          next_hop_in_ip_address = route.next_hop_type == "VirtualAppliance" ? route.next_hop_in_ip_address : null
        }
      ]
    ]) : item.key => item
  }

  # Flatten subnet associations into a map for for_each
  subnet_associations = {
    for item in flatten([
      for rt_key, rt in var.route_tables : [
        for idx, subnet_id in rt.subnet_ids : {
          key       = "${rt_key}-${idx}"
          rt_key    = rt_key
          subnet_id = subnet_id
        }
      ]
    ]) : item.key => item
  }
}

resource "azurerm_route_table" "this" {
  for_each = var.route_tables

  name                          = each.value.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  bgp_route_propagation_enabled = each.value.bgp_route_propagation_enabled
  tags                          = local.tags
}

resource "azurerm_route" "this" {
  for_each = local.routes

  name                   = each.value.name
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.this[each.value.rt_key].name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_in_ip_address
}

resource "azurerm_subnet_route_table_association" "this" {
  for_each = local.subnet_associations

  subnet_id      = each.value.subnet_id
  route_table_id = azurerm_route_table.this[each.value.rt_key].id
}
