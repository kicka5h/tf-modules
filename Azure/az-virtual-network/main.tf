locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)

  # Flatten subnets into a map for for_each
  subnets = {
    for item in flatten([
      for vnet_key, vnet in var.vnets : [
        for subnet_key, subnet in vnet.subnets : {
          key                                         = "${vnet_key}-${subnet_key}"
          vnet_key                                    = vnet_key
          name                                        = subnet_key
          address_prefixes                             = subnet.address_prefixes
          service_endpoints                            = subnet.service_endpoints
          private_endpoint_network_policies            = subnet.private_endpoint_network_policies
          private_link_service_network_policies_enabled = subnet.private_link_service_network_policies_enabled
          delegation                                   = subnet.delegation
        }
      ]
    ]) : item.key => item
  }
}

resource "azurerm_virtual_network" "this" {
  for_each = var.vnets

  name                    = each.value.name
  location                = var.location
  resource_group_name     = var.resource_group_name
  address_space           = each.value.address_space
  dns_servers             = each.value.dns_servers
  flow_timeout_in_minutes = each.value.flow_timeout_in_minutes
  tags                    = local.tags

  dynamic "ddos_protection_plan" {
    for_each = each.value.ddos_protection_plan != null ? [each.value.ddos_protection_plan] : []
    content {
      id     = ddos_protection_plan.value.id
      enable = ddos_protection_plan.value.enable
    }
  }

  dynamic "encryption" {
    for_each = each.value.encryption != null ? [each.value.encryption] : []
    content {
      enforcement = encryption.value.enforcement
    }
  }
}

resource "azurerm_subnet" "this" {
  for_each = local.subnets

  name                                          = each.value.name
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.this[each.value.vnet_key].name
  address_prefixes                              = each.value.address_prefixes
  service_endpoints                             = each.value.service_endpoints
  private_endpoint_network_policies             = each.value.private_endpoint_network_policies
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}
