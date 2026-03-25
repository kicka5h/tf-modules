locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)

  # Flatten public IP associations into a map for for_each
  pip_associations = {
    for item in flatten([
      for gw_key, gw in var.nat_gateways : [
        for idx, pip_id in gw.public_ip_ids : {
          key          = "${gw_key}-${idx}"
          gw_key       = gw_key
          public_ip_id = pip_id
        }
      ]
    ]) : item.key => item
  }

  # Flatten public IP prefix associations into a map for for_each
  prefix_associations = {
    for item in flatten([
      for gw_key, gw in var.nat_gateways : [
        for idx, prefix_id in gw.public_ip_prefix_ids : {
          key                 = "${gw_key}-${idx}"
          gw_key              = gw_key
          public_ip_prefix_id = prefix_id
        }
      ]
    ]) : item.key => item
  }

  # Flatten subnet associations into a map for for_each
  subnet_associations = {
    for item in flatten([
      for gw_key, gw in var.nat_gateways : [
        for idx, subnet_id in gw.subnet_ids : {
          key       = "${gw_key}-${idx}"
          gw_key    = gw_key
          subnet_id = subnet_id
        }
      ]
    ]) : item.key => item
  }
}

resource "azurerm_nat_gateway" "this" {
  for_each = var.nat_gateways

  name                    = each.value.name
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = each.value.sku_name
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
  zones                   = each.value.zones
  tags                    = local.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  for_each = local.pip_associations

  nat_gateway_id       = azurerm_nat_gateway.this[each.value.gw_key].id
  public_ip_address_id = each.value.public_ip_id
}

resource "azurerm_nat_gateway_public_ip_prefix_association" "this" {
  for_each = local.prefix_associations

  nat_gateway_id      = azurerm_nat_gateway.this[each.value.gw_key].id
  public_ip_prefix_id = each.value.public_ip_prefix_id
}

resource "azurerm_subnet_nat_gateway_association" "this" {
  for_each = local.subnet_associations

  subnet_id      = each.value.subnet_id
  nat_gateway_id = azurerm_nat_gateway.this[each.value.gw_key].id
}
