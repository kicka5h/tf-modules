output "private_dns_zone_name" {
  value = azurerm_private_dns_zone.private.0.name

  depends_on = [azurerm_private_dns_zone.private]
}