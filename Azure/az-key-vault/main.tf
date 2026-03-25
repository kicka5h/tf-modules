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

# =================================================================
# Optional: Internal utility module integration
# Uncomment the blocks below to enable az-naming, az-tagging,
# az-diagnostics, and az-budget within this module.
# =================================================================

# --- az-naming: generate compliant resource names ---
# module "naming" {
#   count   = var.naming_config != null ? 1 : 0
#   source  = "github.com/<org>/tf-modules//Azure/az-naming"
#
#   environment = var.naming_config.environment
#   region      = var.naming_config.region
#   workload    = var.naming_config.workload
# }

# --- az-tagging: enforce standard tags ---
# module "tagging" {
#   count   = var.tagging_config != null ? 1 : 0
#   source  = "github.com/<org>/tf-modules//Azure/az-tagging"
#
#   environment         = var.tagging_config.environment
#   owner               = var.tagging_config.owner
#   cost_center         = var.tagging_config.cost_center
#   project             = var.tagging_config.project
#   data_classification = var.tagging_config.data_classification
# }

# --- az-diagnostics: send Key Vault metrics/audit logs to Log Analytics ---
# module "diagnostics" {
#   source   = "github.com/<org>/tf-modules//Azure/az-diagnostics"
#   for_each = var.diagnostics_config != null ? azurerm_key_vault.this : {}
#
#   target_resource_id         = each.value.id
#   log_analytics_workspace_id = var.diagnostics_config.log_analytics_workspace_id
#   storage_account_id         = var.diagnostics_config.storage_account_id
# }

# --- az-budget: apply budget controls ---
# module "budget" {
#   count  = var.budget_config != null ? 1 : 0
#   source = "github.com/<org>/tf-modules//Azure/az-budget"
#
#   amount            = var.budget_config.amount
#   resource_group_id = var.budget_config.resource_group_id
#   start_date        = var.budget_config.start_date
#   contact_emails    = var.budget_config.contact_emails
# }
