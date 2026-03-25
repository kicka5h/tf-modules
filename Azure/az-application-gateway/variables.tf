variable "resource_group_name" {
  description = "Name of the resource group to create application gateways in"
  type        = string
}

variable "location" {
  description = "Azure region for all application gateways"
  type        = string
}

variable "application_gateways" {
  description = "Map of application gateways to create. Key is a logical name, value defines the gateway and all its inline configuration."
  type = map(object({
    name = string
    sku = object({
      name     = string # "Standard_v2", "WAF_v2"
      tier     = string # "Standard_v2", "WAF_v2"
      capacity = optional(number, null)
    })
    autoscale_configuration = optional(object({
      min_capacity = number
      max_capacity = optional(number, null)
    }), null)
    gateway_ip_configuration = object({
      name      = string
      subnet_id = string
    })
    frontend_ip_configurations = map(object({
      name                          = string
      public_ip_address_id          = optional(string, null)
      subnet_id                     = optional(string, null)
      private_ip_address            = optional(string, null)
      private_ip_address_allocation = optional(string, null)
    }))
    frontend_ports = map(object({
      name = string
      port = number
    }))
    backend_address_pools = map(object({
      name         = string
      fqdns        = optional(list(string), [])
      ip_addresses = optional(list(string), [])
    }))
    backend_http_settings = map(object({
      name                                = string
      port                                = number
      protocol                            = string # "Http", "Https"
      cookie_based_affinity               = optional(string, "Disabled")
      request_timeout                     = optional(number, 30)
      path                                = optional(string, null)
      probe_key                           = optional(string, null)
      host_name                           = optional(string, null)
      pick_host_name_from_backend_address = optional(bool, false)
    }))
    http_listeners = map(object({
      name                           = string
      frontend_ip_configuration_name = string
      frontend_port_name             = string
      protocol                       = string # "Http", "Https"
      host_name                      = optional(string, null)
      host_names                     = optional(list(string), [])
      ssl_certificate_name           = optional(string, null)
    }))
    request_routing_rules = map(object({
      name                       = string
      rule_type                  = string # "Basic", "PathBasedRouting"
      http_listener_name         = string
      backend_address_pool_name  = optional(string, null)
      backend_http_settings_name = optional(string, null)
      url_path_map_name          = optional(string, null)
      priority                   = number
    }))
    probes = optional(map(object({
      name                                      = string
      protocol                                  = string
      path                                      = string
      host                                      = optional(string, null)
      interval                                  = optional(number, 30)
      timeout                                   = optional(number, 30)
      unhealthy_threshold                       = optional(number, 3)
      pick_host_name_from_backend_http_settings = optional(bool, false)
    })), {})
    ssl_certificates = optional(map(object({
      name                = string
      data                = optional(string, null)
      password            = optional(string, null)
      key_vault_secret_id = optional(string, null)
    })), {})
    url_path_maps = optional(map(object({
      name                               = string
      default_backend_address_pool_name  = string
      default_backend_http_settings_name = string
      path_rules = map(object({
        name                       = string
        paths                      = list(string)
        backend_address_pool_name  = string
        backend_http_settings_name = string
      }))
    })), {})
    waf_configuration = optional(object({
      enabled          = bool
      firewall_mode    = optional(string, "Prevention") # "Detection", "Prevention"
      rule_set_type    = optional(string, "OWASP")
      rule_set_version = optional(string, "3.2")
    }), null)
    ssl_policy = optional(object({
      policy_type = optional(string, "Predefined")
      policy_name = optional(string, "AppGwSslPolicy20220101S")
    }), null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, gw in var.application_gateways :
      contains(["Standard_v2", "WAF_v2"], gw.sku.name)
    ])
    error_message = "Each application gateway must have sku.name set to one of: Standard_v2, WAF_v2."
  }

  validation {
    condition = alltrue([
      for k, gw in var.application_gateways :
      contains(["Standard_v2", "WAF_v2"], gw.sku.tier)
    ])
    error_message = "Each application gateway must have sku.tier set to one of: Standard_v2, WAF_v2."
  }

  validation {
    condition = alltrue([
      for k, gw in var.application_gateways :
      gw.sku.name != "WAF_v2" || gw.waf_configuration != null
    ])
    error_message = "WAF_v2 SKU requires waf_configuration to be set."
  }
}

variable "tags" {
  description = "Tags to apply to all resources. Merged with default tags."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------
# Optional: Internal utility module variables
# Uncomment to enable naming, tagging, diagnostics, and budget
# enforcement within this module.
# -----------------------------------------------------------------

# variable "naming_config" {
#   description = "Configuration for the az-naming module. Set to null to disable."
#   type = object({
#     environment = string
#     region      = string
#     workload    = string
#   })
#   default = null
# }

# variable "tagging_config" {
#   description = "Configuration for the az-tagging module. Set to null to use var.tags directly."
#   type = object({
#     environment         = string
#     owner               = string
#     cost_center         = string
#     project             = string
#     data_classification = optional(string, "internal")
#   })
#   default = null
# }

# variable "diagnostics_config" {
#   description = "Configuration for the az-diagnostics module. Set to null to disable."
#   type = object({
#     log_analytics_workspace_id = string
#     storage_account_id         = optional(string, null)
#   })
#   default = null
# }

# variable "budget_config" {
#   description = "Configuration for the az-budget module. Set to null to disable."
#   type = object({
#     amount             = number
#     resource_group_id  = string
#     start_date         = string
#     contact_emails     = list(string)
#   })
#   default = null
# }
