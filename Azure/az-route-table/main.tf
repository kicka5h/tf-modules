locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)

  # Flatten routes into a map for for_each
  routes = {
    for item in flatten([
      for rt_key, rt in var.route_tables : [
        for route_key, route in rt.routes : {
          key                    = "${rt_key}-${route_key}"
          rt_key                 = rt_key
          name                   = route_key
          address_prefix         = route.address_prefix
          next_hop_type          = route.next_hop_type
          next_hop_in_ip_address = route.next_hop_type == "VirtualAppliance" ? route.next_hop_in_ip_address : null
        }
      ]
    ]) : item.key => item
  }

  # Flatten subnet associations into a map for for_each
  subnet_associations = {
    for item in flatten([
      for rt_key, rt in var.route_tables : [
        for idx, subnet_id in rt.subnet_ids : {
          key       = "${rt_key}-${idx}"
          rt_key    = rt_key
          subnet_id = subnet_id
        }
      ]
    ]) : item.key => item
  }
}

resource "azurerm_route_table" "this" {
  for_each = var.route_tables

  name                          = each.value.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  bgp_route_propagation_enabled = each.value.bgp_route_propagation_enabled
  tags                          = local.tags
}

resource "azurerm_route" "this" {
  for_each = local.routes

  name                   = each.value.name
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.this[each.value.rt_key].name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_in_ip_address
}

resource "azurerm_subnet_route_table_association" "this" {
  for_each = local.subnet_associations

  subnet_id      = each.value.subnet_id
  route_table_id = azurerm_route_table.this[each.value.rt_key].id
}

# -----------------------------------------------------------------
# Optional: Internal utility module integrations
# Uncomment to enforce naming, tagging, and budget
# at the module level. Callers pass config via the variables above.
# Note: Diagnostics are not supported for route tables.
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
