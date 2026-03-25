output "public_ips" {
  description = "Map of public IPs created, keyed by the logical name"
  value = {
    for k, v in azurerm_public_ip.this : k => {
      id                = v.id
      name              = v.name
      ip_address        = v.ip_address
      fqdn              = v.fqdn
      sku               = v.sku
      allocation_method = v.allocation_method
    }
  }
}

output "public_ip_prefixes" {
  description = "Map of public IP prefixes created, keyed by the logical name"
  value = {
    for k, v in azurerm_public_ip_prefix.this : k => {
      id            = v.id
      name          = v.name
      ip_prefix     = v.ip_prefix
      prefix_length = v.prefix_length
    }
  }
}
