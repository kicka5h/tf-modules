locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)

  # Flatten access policies into a map for for_each
  # Only include policies for vaults where enable_rbac_authorization is false
  access_policies = {
    for item in flatten([
      for kv_key, kv in var.key_vaults : [
        for policy_key, policy in kv.access_policies : {
          key                     = "${kv_key}-${policy_key}"
          kv_key                  = kv_key
          object_id               = policy.object_id
          tenant_id               = coalesce(policy.tenant_id, data.azurerm_client_config.current.tenant_id)
          key_permissions         = policy.key_permissions
          secret_permissions      = policy.secret_permissions
          certificate_permissions = policy.certificate_permissions
          storage_permissions     = policy.storage_permissions
        }
      ] if kv.enable_rbac_authorization == false
    ]) : item.key => item
  }
}

resource "azurerm_key_vault" "this" {
  for_each = var.key_vaults

  name                          = each.value.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = each.value.sku_name
  soft_delete_retention_days    = each.value.soft_delete_retention_days
  purge_protection_enabled      = each.value.purge_protection_enabled
  enable_rbac_authorization     = each.value.enable_rbac_authorization
  public_network_access_enabled = each.value.public_network_access_enabled
  enabled_for_deployment          = each.value.enabled_for_deployment
  enabled_for_disk_encryption     = each.value.enabled_for_disk_encryption
  enabled_for_template_deployment = each.value.enabled_for_template_deployment

  dynamic "network_acls" {
    for_each = each.value.network_acls != null ? [each.value.network_acls] : []
    content {
      default_action             = network_acls.value.default_action
      bypass                     = network_acls.value.bypass
      ip_rules                   = network_acls.value.ip_rules
      virtual_network_subnet_ids = network_acls.value.virtual_network_subnet_ids
    }
  }

  tags = merge(local.tags, each.value.tags)
}

resource "azurerm_key_vault_access_policy" "this" {
  for_each = local.access_policies

  key_vault_id            = azurerm_key_vault.this[each.value.kv_key].id
  tenant_id               = each.value.tenant_id
  object_id               = each.value.object_id
  key_permissions         = each.value.key_permissions
  secret_permissions      = each.value.secret_permissions
  certificate_permissions = each.value.certificate_permissions
  storage_permissions     = each.value.storage_permissions
}
