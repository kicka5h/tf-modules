locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)

  public_zones  = { for k, v in var.dns_zones : k => v if v.type == "public" }
  private_zones = { for k, v in var.dns_zones : k => v if v.type == "private" }

  # Flatten private zone vnet links into a map for for_each
  private_vnet_links = {
    for item in flatten([
      for zone_key, zone in local.private_zones : [
        for link_key, link in zone.vnet_links : {
          key                  = "${zone_key}-${link_key}"
          zone_key             = zone_key
          virtual_network_id   = link.virtual_network_id
          registration_enabled = link.registration_enabled
        }
      ]
    ]) : item.key => item
  }
}

resource "azurerm_dns_zone" "public" {
  for_each = local.public_zones

  name                = each.value.name
  resource_group_name = var.resource_group_name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "private" {
  for_each = local.private_zones

  name                = each.value.name
  resource_group_name = var.resource_group_name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = local.private_vnet_links

  name                  = each.key
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.private[each.value.zone_key].name
  virtual_network_id    = each.value.virtual_network_id
  registration_enabled  = each.value.registration_enabled
  tags                  = local.tags
}
