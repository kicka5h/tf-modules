resource "random_string" "random" {
  length           = 16
  special          = true
  override_special = "/@£$"
}

resource "azurerm_dns_zone" "public" {
  count               = var.public_dns_zone_name == null ? 1 : 0
  name                = var.public_dns_zone_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone" "private" {
  count               = var.private_dns_zone_name == null ? 0 : 1
  name                = var.private_dns_zone_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_vnet_link" {
  count                 = var.enable_network_link == true ? 1 : 0
  name                  = "vnet-link-${random.this}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.private.0.name
  registration_enabled  = lookup(var.private_registration_enabled, "private_registration_enabled", false)
  virtual_network_id    = var.private_dns_zone_vnet_links[count.index]
  tags                  = var.tags
}