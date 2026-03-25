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

# -----------------------------------------------------------------
# Optional: Internal utility module integrations
# Uncomment to enforce naming, tagging, diagnostics, budget, and
# IPAM at the module level. Callers pass config via the variables above.
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
#     for k, v in azurerm_virtual_network.this : k => {
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

# --- IPAM (calculates addresses from allocation plan) ---
# module "ipam" {
#   source         = "../az-ipam"
#   count          = var.ipam_config != null ? 1 : 0
#   root_cidrs     = var.ipam_config.root_cidrs
#   reserved_cidrs = var.ipam_config.reserved_cidrs
#   allocations    = var.ipam_config.allocations
# }
# Then use module.ipam[0].vnet_cidrs and module.ipam[0].subnet_cidrs
# to populate address_space and address_prefixes
