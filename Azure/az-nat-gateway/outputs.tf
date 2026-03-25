output "nat_gateways" {
  description = "Map of NAT gateways created, keyed by the logical name"
  value = {
    for k, v in azurerm_nat_gateway.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "pip_associations" {
  description = "Map of public IP to NAT gateway associations created"
  value = {
    for k, v in azurerm_nat_gateway_public_ip_association.this : k => {
      id                   = v.id
      nat_gateway_id       = v.nat_gateway_id
      public_ip_address_id = v.public_ip_address_id
    }
  }
}

output "prefix_associations" {
  description = "Map of public IP prefix to NAT gateway associations created"
  value = {
    for k, v in azurerm_nat_gateway_public_ip_prefix_association.this : k => {
      id                  = v.id
      nat_gateway_id      = v.nat_gateway_id
      public_ip_prefix_id = v.public_ip_prefix_id
    }
  }
}

output "subnet_associations" {
  description = "Map of subnet to NAT gateway associations created"
  value = {
    for k, v in azurerm_subnet_nat_gateway_association.this : k => {
      id        = v.id
      subnet_id = v.subnet_id
    }
  }
}
