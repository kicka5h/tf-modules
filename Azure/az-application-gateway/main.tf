locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)

  # Parse Spamhaus DROP + EDROP into a combined list of CIDRs
  spamhaus_cidrs = distinct(concat(
    [
      for line in split("\n", data.http.spamhaus_drop.response_body) :
      trimspace(split(";", line)[0])
      if trimspace(line) != "" && !startswith(trimspace(line), ";") && !startswith(trimspace(line), "#")
    ],
    [
      for line in split("\n", data.http.spamhaus_edrop.response_body) :
      trimspace(split(";", line)[0])
      if trimspace(line) != "" && !startswith(trimspace(line), ";") && !startswith(trimspace(line), "#")
    ]
  ))

  # Parse custom org IP blocklist
  custom_ip_cidrs = [
    for line in split("\n", data.http.custom_ip_blocklist.response_body) :
    trimspace(line)
    if trimspace(line) != "" && !startswith(trimspace(line), "#")
  ]

  # Combined IP blocklist
  blocked_cidrs = distinct(concat(local.spamhaus_cidrs, local.custom_ip_cidrs))

  # WAF_v2 gateways that get an enforced WAF policy
  waf_gateways = {
    for k, gw in var.application_gateways : k => gw
    if gw.sku.name == "WAF_v2"
  }
}

resource "azurerm_web_application_firewall_policy" "this" {
  for_each = local.waf_gateways

  name                = "${each.value.name}-waf-policy"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags

  policy_settings {
    enabled = true
    mode    = each.value.waf_configuration != null ? each.value.waf_configuration.firewall_mode : "Prevention"
  }

  managed_rules {
    managed_rule_set {
      type    = each.value.waf_configuration != null ? each.value.waf_configuration.rule_set_type : "OWASP"
      version = each.value.waf_configuration != null ? each.value.waf_configuration.rule_set_version : "3.2"
    }
  }

  custom_rules {
    name      = "blocklist-deny-inbound"
    priority  = 1
    rule_type = "MatchRule"
    action    = "Block"

    match_conditions {
      match_variables {
        variable_name = "RemoteAddr"
      }
      operator           = "IPMatch"
      negation_condition = false
      match_values       = local.blocked_cidrs
    }
  }
}

resource "azurerm_application_gateway" "this" {
  for_each = var.application_gateways

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  firewall_policy_id  = contains(keys(local.waf_gateways), each.key) ? azurerm_web_application_firewall_policy.this[each.key].id : null
  tags                = local.tags

  sku {
    name     = each.value.sku.name
    tier     = each.value.sku.tier
    capacity = each.value.autoscale_configuration == null ? each.value.sku.capacity : null
  }

  dynamic "autoscale_configuration" {
    for_each = each.value.autoscale_configuration != null ? [each.value.autoscale_configuration] : []
    content {
      min_capacity = autoscale_configuration.value.min_capacity
      max_capacity = autoscale_configuration.value.max_capacity
    }
  }

  gateway_ip_configuration {
    name      = each.value.gateway_ip_configuration.name
    subnet_id = each.value.gateway_ip_configuration.subnet_id
  }

  dynamic "frontend_ip_configuration" {
    for_each = each.value.frontend_ip_configurations
    content {
      name                          = frontend_ip_configuration.value.name
      public_ip_address_id          = frontend_ip_configuration.value.public_ip_address_id
      subnet_id                     = frontend_ip_configuration.value.subnet_id
      private_ip_address            = frontend_ip_configuration.value.private_ip_address
      private_ip_address_allocation = frontend_ip_configuration.value.private_ip_address_allocation
    }
  }

  dynamic "frontend_port" {
    for_each = each.value.frontend_ports
    content {
      name = frontend_port.value.name
      port = frontend_port.value.port
    }
  }

  dynamic "backend_address_pool" {
    for_each = each.value.backend_address_pools
    content {
      name         = backend_address_pool.value.name
      fqdns        = backend_address_pool.value.fqdns
      ip_addresses = backend_address_pool.value.ip_addresses
    }
  }

  dynamic "backend_http_settings" {
    for_each = each.value.backend_http_settings
    content {
      name                                = backend_http_settings.value.name
      port                                = backend_http_settings.value.port
      protocol                            = backend_http_settings.value.protocol
      cookie_based_affinity               = backend_http_settings.value.cookie_based_affinity
      request_timeout                     = backend_http_settings.value.request_timeout
      path                                = backend_http_settings.value.path
      probe_name                          = backend_http_settings.value.probe_key != null ? each.value.probes[backend_http_settings.value.probe_key].name : null
      host_name                           = backend_http_settings.value.host_name
      pick_host_name_from_backend_address = backend_http_settings.value.pick_host_name_from_backend_address
    }
  }

  dynamic "http_listener" {
    for_each = each.value.http_listeners
    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = http_listener.value.frontend_ip_configuration_name
      frontend_port_name             = http_listener.value.frontend_port_name
      protocol                       = http_listener.value.protocol
      host_name                      = http_listener.value.host_name
      host_names                     = length(http_listener.value.host_names) > 0 ? http_listener.value.host_names : null
      ssl_certificate_name           = http_listener.value.ssl_certificate_name
    }
  }

  dynamic "request_routing_rule" {
    for_each = each.value.request_routing_rules
    content {
      name                       = request_routing_rule.value.name
      rule_type                  = request_routing_rule.value.rule_type
      http_listener_name         = request_routing_rule.value.http_listener_name
      backend_address_pool_name  = request_routing_rule.value.backend_address_pool_name
      backend_http_settings_name = request_routing_rule.value.backend_http_settings_name
      url_path_map_name          = request_routing_rule.value.url_path_map_name
      priority                   = request_routing_rule.value.priority
    }
  }

  dynamic "probe" {
    for_each = each.value.probes
    content {
      name                                      = probe.value.name
      protocol                                  = probe.value.protocol
      path                                      = probe.value.path
      host                                      = probe.value.host
      interval                                  = probe.value.interval
      timeout                                   = probe.value.timeout
      unhealthy_threshold                       = probe.value.unhealthy_threshold
      pick_host_name_from_backend_http_settings = probe.value.pick_host_name_from_backend_http_settings
    }
  }

  dynamic "ssl_certificate" {
    for_each = each.value.ssl_certificates
    content {
      name                = ssl_certificate.value.name
      data                = ssl_certificate.value.data
      password            = ssl_certificate.value.password
      key_vault_secret_id = ssl_certificate.value.key_vault_secret_id
    }
  }

  dynamic "url_path_map" {
    for_each = each.value.url_path_maps
    content {
      name                               = url_path_map.value.name
      default_backend_address_pool_name  = url_path_map.value.default_backend_address_pool_name
      default_backend_http_settings_name = url_path_map.value.default_backend_http_settings_name

      dynamic "path_rule" {
        for_each = url_path_map.value.path_rules
        content {
          name                       = path_rule.value.name
          paths                      = path_rule.value.paths
          backend_address_pool_name  = path_rule.value.backend_address_pool_name
          backend_http_settings_name = path_rule.value.backend_http_settings_name
        }
      }
    }
  }

  dynamic "waf_configuration" {
    for_each = each.value.waf_configuration != null ? [each.value.waf_configuration] : []
    content {
      enabled          = waf_configuration.value.enabled
      firewall_mode    = waf_configuration.value.firewall_mode
      rule_set_type    = waf_configuration.value.rule_set_type
      rule_set_version = waf_configuration.value.rule_set_version
    }
  }

  dynamic "ssl_policy" {
    for_each = each.value.ssl_policy != null ? [each.value.ssl_policy] : []
    content {
      policy_type = ssl_policy.value.policy_type
      policy_name = ssl_policy.value.policy_name
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
#     for k, v in azurerm_application_gateway.this : k => {
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
