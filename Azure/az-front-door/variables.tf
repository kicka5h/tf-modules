variable "resource_group_name" {
  description = "Name of the resource group to create Front Door profiles in"
  type        = string
}

variable "front_doors" {
  description = "Map of Front Door profiles to create. Key is a logical name, value defines the profile and all its inline configuration."
  type = map(object({
    name     = string
    sku_name = string # "Standard_AzureFrontDoor" or "Premium_AzureFrontDoor"
    endpoints = optional(map(object({
      name    = string
      enabled = optional(bool, true)
    })), {})
    origin_groups = optional(map(object({
      name = string
      load_balancing = optional(object({
        sample_size                        = optional(number, 4)
        successful_samples_required        = optional(number, 3)
        additional_latency_in_milliseconds = optional(number, 50)
      }), {})
      health_probe = optional(object({
        path                = optional(string, "/")
        protocol            = optional(string, "Https")
        interval_in_seconds = optional(number, 100)
        request_type        = optional(string, "HEAD")
      }), null)
      origins = map(object({
        name                           = string
        host_name                      = string
        http_port                      = optional(number, 80)
        https_port                     = optional(number, 443)
        origin_host_header             = optional(string, null)
        certificate_name_check_enabled = optional(bool, true)
        priority                       = optional(number, 1)
        weight                         = optional(number, 1000)
        enabled                        = optional(bool, true)
      }))
    })), {})
    custom_waf_rules = optional(map(object({
      name     = string
      priority = number # must be >= 100 (1-99 reserved for module-enforced blocklists)
      type     = optional(string, "MatchRule")
      action   = string # "Allow", "Block", "Log", "Redirect"
      match_conditions = list(object({
        match_variable     = string
        selector           = optional(string, null)
        operator           = string
        negation_condition = optional(bool, false)
        match_values       = list(string)
        transforms         = optional(list(string), [])
      }))
    })), {})
    routes = optional(map(object({
      name                   = string
      endpoint_key           = string
      origin_group_key       = string
      patterns_to_match      = optional(list(string), ["/*"])
      supported_protocols    = optional(list(string), ["Http", "Https"])
      forwarding_protocol    = optional(string, "HttpsOnly")
      https_redirect_enabled = optional(bool, true)
      link_to_default_domain = optional(bool, true)
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, fd in var.front_doors :
      contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], fd.sku_name)
    ])
    error_message = "Each Front Door profile must have sku_name set to one of: Standard_AzureFrontDoor, Premium_AzureFrontDoor."
  }

  validation {
    condition = alltrue(flatten([
      for fd_key, fd in var.front_doors : [
        for rule_key, rule in fd.custom_waf_rules :
        rule.priority >= 100
      ]
    ]))
    error_message = "User-defined WAF custom rule priorities must be >= 100. Priorities 1-99 are reserved for module-enforced blocklist rules."
  }
}

variable "fqdn_blocklist_max" {
  description = "Maximum number of FQDNs to import from the Ultimate Hosts Blacklist. Set to 0 to disable."
  type        = number
  default     = 1000
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
