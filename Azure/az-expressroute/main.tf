locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)

  # Flatten peerings into a map for for_each
  peerings = {
    for item in flatten([
      for circuit_key, circuit in var.expressroute_circuits : [
        for peering_key, peering in circuit.peerings : {
          key                           = "${circuit_key}-${peering_key}"
          circuit_key                   = circuit_key
          peering_type                  = peering.peering_type
          vlan_id                       = peering.vlan_id
          primary_peer_address_prefix   = peering.primary_peer_address_prefix
          secondary_peer_address_prefix = peering.secondary_peer_address_prefix
          peer_asn                      = peering.peer_asn
          shared_key                    = peering.shared_key
          microsoft_peering_config      = peering.microsoft_peering_config
        }
      ]
    ]) : item.key => item
  }
}

resource "azurerm_express_route_circuit" "this" {
  for_each = var.expressroute_circuits

  name                     = each.value.name
  location                 = var.location
  resource_group_name      = var.resource_group_name
  service_provider_name    = each.value.service_provider_name
  peering_location         = each.value.peering_location
  bandwidth_in_mbps        = each.value.bandwidth_in_mbps
  allow_classic_operations = each.value.allow_classic_operations
  tags                     = local.tags

  sku {
    tier   = each.value.sku.tier
    family = each.value.sku.family
  }
}

resource "azurerm_express_route_circuit_peering" "this" {
  for_each = local.peerings

  peering_type                  = each.value.peering_type
  express_route_circuit_name    = azurerm_express_route_circuit.this[each.value.circuit_key].name
  resource_group_name           = var.resource_group_name
  vlan_id                       = each.value.vlan_id
  primary_peer_address_prefix   = each.value.primary_peer_address_prefix
  secondary_peer_address_prefix = each.value.secondary_peer_address_prefix
  peer_asn                      = each.value.peer_asn
  shared_key                    = each.value.shared_key

  dynamic "microsoft_peering_config" {
    for_each = each.value.microsoft_peering_config != null ? [each.value.microsoft_peering_config] : []
    content {
      advertised_public_prefixes = microsoft_peering_config.value.advertised_public_prefixes
    }
  }
}

# -----------------------------------------------------------------
# Optional: Internal utility module integrations
# Uncomment to enforce naming, tagging, diagnostics, and budget
# at the module level. Callers pass config via the variables above.
# -----------------------------------------------------------------

# --- Naming (generates standardized names for all resources) ---
# module "naming" {
#   source      = "../az-naming"
#   count       = var.naming_config != null ? 1 : 0
#   environment = var.naming_config.environment
#   region      = var.naming_config.region
#   workload    = var.naming_config.workload
# }
# Then replace hardcoded names with: module.naming[0].<resource_type>

# --- Tagging (enforces required tags on all resources) ---
# module "tagging" {
#   source              = "../az-tagging"
#   count               = var.tagging_config != null ? 1 : 0
#   environment         = var.tagging_config.environment
#   owner               = var.tagging_config.owner
#   cost_center         = var.tagging_config.cost_center
#   project             = var.tagging_config.project
#   data_classification = var.tagging_config.data_classification
#   additional_tags     = var.tags
# }
# Then replace local.tags with: var.tagging_config != null ? module.tagging[0].tags : local.tags

# --- Diagnostics (auto-creates diagnostic settings for all resources) ---
# module "diagnostics" {
#   source                     = "../az-diagnostics"
#   count                      = var.diagnostics_config != null ? 1 : 0
#   log_analytics_workspace_id = var.diagnostics_config.log_analytics_workspace_id
#   diagnostic_settings = {
#     for k, v in azurerm_express_route_circuit.this : k => {
#       name               = "diag-${v.name}"
#       target_resource_id = v.id
#       storage_account_id = var.diagnostics_config.storage_account_id
#     }
#   }
# }

# --- Budget (creates cost alert for the resource group) ---
# module "budget" {
#   source = "../az-budget"
#   count  = var.budget_config != null ? 1 : 0
#   budgets = {
#     this = {
#       name              = "budget-${var.resource_group_name}"
#       resource_group_id = var.budget_config.resource_group_id
#       amount            = var.budget_config.amount
#       time_period       = { start_date = var.budget_config.start_date }
#       notifications = {
#         actual_80 = {
#           threshold      = 80
#           contact_emails = var.budget_config.contact_emails
#         }
#         actual_100 = {
#           threshold      = 100
#           contact_emails = var.budget_config.contact_emails
#         }
#       }
#     }
#   }
# }
