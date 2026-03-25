locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_public_ip" "this" {
  for_each = var.public_ips

  name                    = each.value.name
  location                = var.location
  resource_group_name     = var.resource_group_name
  allocation_method       = each.value.allocation_method
  sku                     = each.value.sku
  sku_tier                = each.value.sku_tier
  zones                   = each.value.zones
  ip_version              = each.value.ip_version
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
  domain_name_label       = each.value.domain_name_label
  reverse_fqdn            = each.value.reverse_fqdn
  ip_tags                 = each.value.ip_tags
  public_ip_prefix_id     = each.value.public_ip_prefix_id
  tags                    = local.tags
}

resource "azurerm_public_ip_prefix" "this" {
  for_each = var.public_ip_prefixes

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = each.value.sku
  prefix_length       = each.value.prefix_length
  zones               = each.value.zones
  ip_version          = each.value.ip_version
  tags                = local.tags
}
