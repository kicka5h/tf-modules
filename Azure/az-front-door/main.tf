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

  # Parse Ultimate Hosts Blacklist into FQDNs
  # Format: "0.0.0.0 bad-domain.com" or "127.0.0.1 bad-domain.com"
  _all_blocklist_fqdns = var.fqdn_blocklist_max > 0 ? [
    for line in split("\n", data.http.hosts_blacklist.response_body) :
    trimspace(element(split(" ", trimspace(line)), length(split(" ", trimspace(line))) - 1))
    if length(trimspace(line)) > 0
    && !startswith(trimspace(line), "#")
    && (startswith(trimspace(line), "0.0.0.0") || startswith(trimspace(line), "127.0.0.1"))
    && trimspace(element(split(" ", trimspace(line)), length(split(" ", trimspace(line))) - 1)) != "localhost"
  ] : []

  _ultimate_hosts_fqdns = slice(
    local._all_blocklist_fqdns,
    0,
    min(var.fqdn_blocklist_max, length(local._all_blocklist_fqdns))
  )

  # Parse custom org FQDN blocklist
  _custom_fqdns = [
    for line in split("\n", data.http.custom_fqdn_blocklist.response_body) :
    trimspace(line)
    if trimspace(line) != "" && !startswith(trimspace(line), "#")
  ]

  # Combined FQDN blocklist
  blocked_fqdns = distinct(concat(local._ultimate_hosts_fqdns, local._custom_fqdns))

  # Flatten endpoints: key = "${fd_key}-${ep_key}"
  endpoints = {
    for item in flatten([
      for fd_key, fd in var.front_doors : [
        for ep_key, ep in fd.endpoints : {
          key    = "${fd_key}-${ep_key}"
          fd_key = fd_key
          ep_key = ep_key
          name   = ep.name
          enabled = ep.enabled
        }
      ]
    ]) : item.key => item
  }

  # Flatten origin_groups: key = "${fd_key}-${og_key}"
  origin_groups = {
    for item in flatten([
      for fd_key, fd in var.front_doors : [
        for og_key, og in fd.origin_groups : {
          key            = "${fd_key}-${og_key}"
          fd_key         = fd_key
          og_key         = og_key
          name           = og.name
          load_balancing = og.load_balancing
          health_probe   = og.health_probe
        }
      ]
    ]) : item.key => item
  }

  # Flatten origins three levels deep: key = "${fd_key}-${og_key}-${origin_key}"
  origins = {
    for item in flatten([
      for fd_key, fd in var.front_doors : [
        for og_key, og in fd.origin_groups : [
          for origin_key, origin in og.origins : {
            key                            = "${fd_key}-${og_key}-${origin_key}"
            fd_key                         = fd_key
            og_key                         = og_key
            origin_key                     = origin_key
            og_flat_key                    = "${fd_key}-${og_key}"
            name                           = origin.name
            host_name                      = origin.host_name
            http_port                      = origin.http_port
            https_port                     = origin.https_port
            origin_host_header             = origin.origin_host_header
            certificate_name_check_enabled = origin.certificate_name_check_enabled
            priority                       = origin.priority
            weight                         = origin.weight
            enabled                        = origin.enabled
          }
        ]
      ]
    ]) : item.key => item
  }

  # Flatten routes: key = "${fd_key}-${route_key}"
  routes = {
    for item in flatten([
      for fd_key, fd in var.front_doors : [
        for route_key, route in fd.routes : {
          key                    = "${fd_key}-${route_key}"
          fd_key                 = fd_key
          route_key              = route_key
          name                   = route.name
          endpoint_flat_key      = "${fd_key}-${route.endpoint_key}"
          origin_group_flat_key  = "${fd_key}-${route.origin_group_key}"
          patterns_to_match      = route.patterns_to_match
          supported_protocols    = route.supported_protocols
          forwarding_protocol    = route.forwarding_protocol
          https_redirect_enabled = route.https_redirect_enabled
          link_to_default_domain = route.link_to_default_domain
        }
      ]
    ]) : item.key => item
  }

  # Premium profiles that get an enforced WAF policy
  premium_profiles = {
    for k, fd in var.front_doors : k => fd
    if fd.sku_name == "Premium_AzureFrontDoor"
  }
}

resource "azurerm_cdn_frontdoor_profile" "this" {
  for_each = var.front_doors

  name                = each.value.name
  resource_group_name = var.resource_group_name
  sku_name            = each.value.sku_name
  tags                = local.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  for_each = local.endpoints

  name                     = each.value.name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this[each.value.fd_key].id
  enabled                  = each.value.enabled
  tags                     = local.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "this" {
  for_each = local.origin_groups

  name                     = each.value.name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this[each.value.fd_key].id

  load_balancing {
    sample_size                        = each.value.load_balancing.sample_size
    successful_samples_required        = each.value.load_balancing.successful_samples_required
    additional_latency_in_milliseconds = each.value.load_balancing.additional_latency_in_milliseconds
  }

  dynamic "health_probe" {
    for_each = each.value.health_probe != null ? [each.value.health_probe] : []
    content {
      path                = health_probe.value.path
      protocol            = health_probe.value.protocol
      interval_in_seconds = health_probe.value.interval_in_seconds
      request_type        = health_probe.value.request_type
    }
  }
}

resource "azurerm_cdn_frontdoor_origin" "this" {
  for_each = local.origins

  name                           = each.value.name
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.this[each.value.og_flat_key].id
  host_name                      = each.value.host_name
  http_port                      = each.value.http_port
  https_port                     = each.value.https_port
  origin_host_header             = each.value.origin_host_header
  certificate_name_check_enabled = each.value.certificate_name_check_enabled
  priority                       = each.value.priority
  weight                         = each.value.weight
  enabled                        = each.value.enabled
}

resource "azurerm_cdn_frontdoor_route" "this" {
  for_each = local.routes

  name                          = each.value.name
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this[each.value.endpoint_flat_key].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this[each.value.origin_group_flat_key].id
  cdn_frontdoor_origin_ids      = [
    for k, origin in local.origins :
    azurerm_cdn_frontdoor_origin.this[k].id
    if origin.og_flat_key == each.value.origin_group_flat_key
  ]
  patterns_to_match      = each.value.patterns_to_match
  supported_protocols    = each.value.supported_protocols
  forwarding_protocol    = each.value.forwarding_protocol
  https_redirect_enabled = each.value.https_redirect_enabled
  link_to_default_domain = each.value.link_to_default_domain
}

resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
  for_each = local.premium_profiles

  name                              = "${replace(each.value.name, "-", "")}wafpolicy"
  resource_group_name               = var.resource_group_name
  sku_name                          = each.value.sku_name
  mode                              = "Prevention"
  enabled                           = true
  tags                              = local.tags

  custom_rule {
    name     = "BlocklistDenyByIP"
    type     = "MatchRule"
    priority = 1
    action   = "Block"

    match_condition {
      match_variable     = "RemoteAddr"
      operator           = "IPMatch"
      negation_condition = false
      match_values       = local.blocked_cidrs
    }
  }

  dynamic "custom_rule" {
    for_each = length(local.blocked_fqdns) > 0 ? [1] : []
    content {
      name     = "BlocklistDenyByFQDN"
      type     = "MatchRule"
      priority = 2
      action   = "Block"

      match_condition {
        match_variable     = "RequestHeader"
        selector           = "Host"
        operator           = "Contains"
        negation_condition = false
        match_values       = local.blocked_fqdns
        transforms         = ["Lowercase"]
      }
    }
  }

  # Caller-defined custom WAF rules (priority >= 100)
  dynamic "custom_rule" {
    for_each = each.value.custom_waf_rules
    content {
      name     = custom_rule.value.name
      type     = custom_rule.value.type
      priority = custom_rule.value.priority
      action   = custom_rule.value.action

      dynamic "match_condition" {
        for_each = custom_rule.value.match_conditions
        content {
          match_variable     = match_condition.value.match_variable
          selector           = match_condition.value.selector
          operator           = match_condition.value.operator
          negation_condition = match_condition.value.negation_condition
          match_values       = match_condition.value.match_values
          transforms         = match_condition.value.transforms
        }
      }
    }
  }

  managed_rule {
    type    = "DefaultRuleSet"
    version = "1.0"
    action  = "Block"
  }

  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
    action  = "Block"
  }
}

resource "azurerm_cdn_frontdoor_security_policy" "this" {
  for_each = local.premium_profiles

  name                     = "${each.value.name}-security-policy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this[each.key].id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.this[each.key].id

      association {
        patterns_to_match = ["/*"]

        dynamic "domain" {
          for_each = {
            for k, ep in local.endpoints : k => ep
            if ep.fd_key == each.key
          }
          content {
            cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.this[domain.key].id
          }
        }
      }
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
#     for k, v in azurerm_cdn_frontdoor_profile.this : k => {
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
