output "nsgs" {
  description = "Map of network security groups created, keyed by the logical name"
  value = {
    for k, v in azurerm_network_security_group.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "rules" {
  description = "Map of security rules created, keyed by nsg-rule logical name"
  value = {
    for k, v in azurerm_network_security_rule.this : k => {
      id        = v.id
      name      = v.name
      priority  = v.priority
      direction = v.direction
      access    = v.access
    }
  }
}

output "subnet_associations" {
  description = "Map of subnet-to-NSG associations created"
  value = {
    for k, v in azurerm_subnet_network_security_group_association.this : k => {
      id        = v.id
      subnet_id = v.subnet_id
    }
  }
}

output "spamhaus_rules" {
  description = "Map of Spamhaus DROP+EDROP deny rules enforced on all NSGs"
  value = {
    inbound = {
      for k, v in azurerm_network_security_rule.spamhaus_deny_inbound : k => {
        id   = v.id
        name = v.name
      }
    }
    outbound = {
      for k, v in azurerm_network_security_rule.spamhaus_deny_outbound : k => {
        id   = v.id
        name = v.name
      }
    }
  }
}
