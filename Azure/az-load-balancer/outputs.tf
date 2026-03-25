output "load_balancers" {
  description = "Map of load balancers created, keyed by the logical name"
  value = {
    for k, v in azurerm_lb.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "backend_pools" {
  description = "Map of backend address pools created, keyed by lb-pool logical name"
  value = {
    for k, v in azurerm_lb_backend_address_pool.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "probes" {
  description = "Map of health probes created, keyed by lb-probe logical name"
  value = {
    for k, v in azurerm_lb_probe.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "rules" {
  description = "Map of load balancer rules created, keyed by lb-rule logical name"
  value = {
    for k, v in azurerm_lb_rule.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "nat_rules" {
  description = "Map of NAT rules created, keyed by lb-nat logical name"
  value = {
    for k, v in azurerm_lb_nat_rule.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "outbound_rules" {
  description = "Map of outbound rules created, keyed by lb-outbound logical name"
  value = {
    for k, v in azurerm_lb_outbound_rule.this : k => {
      id   = v.id
      name = v.name
    }
  }
}
