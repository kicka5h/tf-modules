locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_container_registry" "this" {
  for_each = var.container_registries

  name                          = each.value.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = each.value.sku
  admin_enabled                 = each.value.admin_enabled
  zone_redundancy_enabled       = each.value.zone_redundancy_enabled
  public_network_access_enabled = each.value.public_network_access_enabled
  network_rule_bypass_option    = each.value.network_rule_bypass_option

  trust_policy {
    enabled = each.value.trust_policy_enabled
  }

  dynamic "retention_policy" {
    for_each = each.value.retention_policy != null ? [each.value.retention_policy] : []
    content {
      days    = retention_policy.value.days
      enabled = retention_policy.value.enabled
    }
  }

  dynamic "georeplications" {
    for_each = each.value.georeplications
    content {
      location                = georeplications.value.location
      zone_redundancy_enabled = georeplications.value.zone_redundancy_enabled
      tags                    = merge(local.tags, each.value.tags, georeplications.value.tags)
    }
  }

  dynamic "encryption" {
    for_each = each.value.encryption != null ? [each.value.encryption] : []
    content {
      key_vault_key_id   = encryption.value.key_vault_key_id
      identity_client_id = encryption.value.identity_client_id
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  tags = merge(local.tags, each.value.tags)
}
