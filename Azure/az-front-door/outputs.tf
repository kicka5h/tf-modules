output "profiles" {
  description = "Map of Front Door profiles created, keyed by the logical name"
  value = {
    for k, v in azurerm_cdn_frontdoor_profile.this : k => {
      id       = v.id
      name     = v.name
      sku_name = v.sku_name
    }
  }
}

output "endpoints" {
  description = "Map of Front Door endpoints created, keyed by the flattened key"
  value = {
    for k, v in azurerm_cdn_frontdoor_endpoint.this : k => {
      id        = v.id
      name      = v.name
      host_name = v.host_name
    }
  }
}

output "origin_groups" {
  description = "Map of Front Door origin groups created, keyed by the flattened key"
  value = {
    for k, v in azurerm_cdn_frontdoor_origin_group.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "origins" {
  description = "Map of Front Door origins created, keyed by the flattened key"
  value = {
    for k, v in azurerm_cdn_frontdoor_origin.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "routes" {
  description = "Map of Front Door routes created, keyed by the flattened key"
  value = {
    for k, v in azurerm_cdn_frontdoor_route.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "waf_policies" {
  description = "Map of WAF policies created for Premium profiles, keyed by the logical name"
  value = {
    for k, v in azurerm_cdn_frontdoor_firewall_policy.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "blocklist_ip_count" {
  description = "Number of IP CIDRs blocked via WAF custom rules (Spamhaus DROP+EDROP + custom org list)"
  value       = length(local.blocked_cidrs)
}

output "blocklist_fqdn_count" {
  description = "Number of FQDNs blocked via WAF custom rules (Ultimate Hosts Blacklist + custom org list)"
  value       = length(local.blocked_fqdns)
}
