locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)

  # Flatten containers into a map for for_each
  containers = {
    for item in flatten([
      for sa_key, sa in var.storage_accounts : [
        for c_key, c in sa.containers : {
          key                   = "${sa_key}-${c_key}"
          sa_key                = sa_key
          name                  = c.name
          container_access_type = c.container_access_type
        }
      ]
    ]) : item.key => item
  }

  # Flatten file shares into a map for for_each
  file_shares = {
    for item in flatten([
      for sa_key, sa in var.storage_accounts : [
        for fs_key, fs in sa.file_shares : {
          key    = "${sa_key}-${fs_key}"
          sa_key = sa_key
          name   = fs.name
          quota  = fs.quota
        }
      ]
    ]) : item.key => item
  }

  # Flatten queues into a map for for_each
  queues = {
    for item in flatten([
      for sa_key, sa in var.storage_accounts : [
        for q_key, q in sa.queues : {
          key    = "${sa_key}-${q_key}"
          sa_key = sa_key
          name   = q.name
        }
      ]
    ]) : item.key => item
  }

  # Flatten tables into a map for for_each
  tables = {
    for item in flatten([
      for sa_key, sa in var.storage_accounts : [
        for t_key, t in sa.tables : {
          key    = "${sa_key}-${t_key}"
          sa_key = sa_key
          name   = t.name
        }
      ]
    ]) : item.key => item
  }
}

resource "azurerm_storage_account" "this" {
  for_each = var.storage_accounts

  name                              = each.value.name
  resource_group_name               = var.resource_group_name
  location                          = var.location
  account_tier                      = each.value.account_tier
  account_replication_type          = each.value.account_replication_type
  account_kind                      = each.value.account_kind
  access_tier                       = each.value.access_tier
  enable_https_traffic_only         = each.value.enable_https_traffic_only
  min_tls_version                   = each.value.min_tls_version
  allow_nested_items_to_be_public   = each.value.allow_nested_items_to_be_public
  shared_access_key_enabled         = each.value.shared_access_key_enabled
  public_network_access_enabled     = each.value.public_network_access_enabled
  infrastructure_encryption_enabled = each.value.infrastructure_encryption_enabled

  dynamic "network_rules" {
    for_each = each.value.network_rules != null ? [each.value.network_rules] : []
    content {
      default_action             = network_rules.value.default_action
      bypass                     = network_rules.value.bypass
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.virtual_network_subnet_ids
    }
  }

  dynamic "blob_properties" {
    for_each = each.value.blob_properties != null ? [each.value.blob_properties] : []
    content {
      versioning_enabled       = blob_properties.value.versioning_enabled
      change_feed_enabled      = blob_properties.value.change_feed_enabled
      last_access_time_enabled = blob_properties.value.last_access_time_enabled

      dynamic "delete_retention_policy" {
        for_each = blob_properties.value.delete_retention_policy != null ? [blob_properties.value.delete_retention_policy] : []
        content {
          days = delete_retention_policy.value.days
        }
      }

      dynamic "container_delete_retention_policy" {
        for_each = blob_properties.value.container_delete_retention_policy != null ? [blob_properties.value.container_delete_retention_policy] : []
        content {
          days = container_delete_retention_policy.value.days
        }
      }
    }
  }

  dynamic "customer_managed_key" {
    for_each = each.value.customer_managed_key != null ? [each.value.customer_managed_key] : []
    content {
      key_vault_key_id          = customer_managed_key.value.key_vault_key_id
      user_assigned_identity_id = customer_managed_key.value.user_assigned_identity_id
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

resource "azurerm_storage_container" "this" {
  for_each = local.containers

  name                  = each.value.name
  storage_account_name  = azurerm_storage_account.this[each.value.sa_key].name
  container_access_type = each.value.container_access_type
}

resource "azurerm_storage_share" "this" {
  for_each = local.file_shares

  name                 = each.value.name
  storage_account_name = azurerm_storage_account.this[each.value.sa_key].name
  quota                = each.value.quota
}

resource "azurerm_storage_queue" "this" {
  for_each = local.queues

  name                 = each.value.name
  storage_account_name = azurerm_storage_account.this[each.value.sa_key].name
}

resource "azurerm_storage_table" "this" {
  for_each = local.tables

  name                 = each.value.name
  storage_account_name = azurerm_storage_account.this[each.value.sa_key].name
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

# --- az-diagnostics: send storage account metrics/logs to Log Analytics ---
# module "diagnostics" {
#   source   = "github.com/<org>/tf-modules//Azure/az-diagnostics"
#   for_each = var.diagnostics_config != null ? azurerm_storage_account.this : {}
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
