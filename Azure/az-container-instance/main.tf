locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_container_group" "this" {
  for_each = var.container_groups

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = each.value.os_type
  restart_policy      = each.value.restart_policy
  ip_address_type     = each.value.ip_address_type
  subnet_ids          = each.value.ip_address_type == "Private" ? each.value.subnet_ids : null
  dns_name_label      = each.value.ip_address_type == "Public" ? each.value.dns_name_label : null
  tags                = merge(local.tags, each.value.tags)

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.type == "SystemAssigned" ? null : identity.value.identity_ids
    }
  }

  dynamic "container" {
    for_each = each.value.containers
    content {
      name   = container.value.name
      image  = container.value.image
      cpu    = container.value.cpu
      memory = container.value.memory

      environment_variables        = container.value.environment_variables
      secure_environment_variables = container.value.secure_environment_variables
      commands                     = length(container.value.commands) > 0 ? container.value.commands : null

      dynamic "ports" {
        for_each = container.value.ports
        content {
          port     = ports.value.port
          protocol = ports.value.protocol
        }
      }

      dynamic "volume" {
        for_each = container.value.volume
        content {
          name                 = volume.value.name
          mount_path           = volume.value.mount_path
          read_only            = volume.value.read_only
          storage_account_name = volume.value.storage_account_name
          storage_account_key  = volume.value.storage_account_key
          share_name           = volume.value.share_name
        }
      }
    }
  }

  dynamic "image_registry_credential" {
    for_each = each.value.image_registry_credential
    content {
      server                    = image_registry_credential.value.server
      username                  = image_registry_credential.value.username
      password                  = image_registry_credential.value.password
      user_assigned_identity_id = image_registry_credential.value.user_assigned_identity_id
    }
  }

  dynamic "dns_config" {
    for_each = each.value.dns_config != null ? [each.value.dns_config] : []
    content {
      nameservers = dns_config.value.nameservers
    }
  }
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

# --- az-diagnostics: send container group metrics/logs to Log Analytics ---
# module "diagnostics" {
#   source   = "github.com/<org>/tf-modules//Azure/az-diagnostics"
#   for_each = var.diagnostics_config != null ? azurerm_container_group.this : {}
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
