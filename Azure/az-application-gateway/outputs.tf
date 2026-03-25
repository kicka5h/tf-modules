output "application_gateways" {
  description = "Map of application gateways created, keyed by the logical name"
  value = {
    for k, v in azurerm_application_gateway.this : k => {
      id   = v.id
      name = v.name
      backend_address_pools = [
        for pool in v.backend_address_pool : {
          id   = pool.id
          name = pool.name
        }
      ]
      http_listeners = [
        for listener in v.http_listener : {
          id   = listener.id
          name = listener.name
        }
      ]
    }
  }
}

output "waf_policies" {
  description = "Map of WAF policies created for WAF_v2 gateways, keyed by the logical name"
  value = {
    for k, v in azurerm_web_application_firewall_policy.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "blocklist_ip_count" {
  description = "Number of IP CIDRs blocked via WAF custom rules (Spamhaus DROP+EDROP + custom org list)"
  value       = length(local.blocked_cidrs)
}
