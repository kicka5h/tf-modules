output "firewalls" {
  description = "Map of firewalls created, keyed by the logical name"
  value = {
    for k, v in azurerm_firewall.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "firewall_policies" {
  description = "Map of firewall policies created, keyed by the logical name"
  value = {
    for k, v in azurerm_firewall_policy.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "rule_collection_groups" {
  description = "Map of rule collection groups created, keyed by firewall-rcg logical name"
  value = {
    for k, v in azurerm_firewall_policy_rule_collection_group.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "blocklist_rule_collection_groups" {
  description = "Map of enforced blocklist rule collection groups on all firewalls with inline policies"
  value = {
    for k, v in azurerm_firewall_policy_rule_collection_group.blocklist : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "blocklist_fqdn_count" {
  description = "Number of FQDNs blocked (Ultimate Hosts Blacklist + custom org list)"
  value       = length(local.blocklist_fqdns)
}

output "blocklist_ip_count" {
  description = "Number of IP CIDRs blocked (Spamhaus DROP+EDROP + custom org list)"
  value       = length(local.blocked_cidrs)
}
