variable "resource_group_name" {
  description = "Name of the resource group to create VNets in"
  type        = string
}

variable "location" {
  description = "Azure region for all VNets"
  type        = string
}

variable "vnets" {
  description = "Map of VNets to create. Key is a logical name, value defines the VNet and its subnets."
  type = map(object({
    name                    = string
    address_space           = list(string)
    dns_servers             = optional(list(string), [])
    flow_timeout_in_minutes = optional(number, null)
    ddos_protection_plan = optional(object({
      id     = string
      enable = bool
    }), null)
    encryption = optional(object({
      enforcement = string # "DropUnencrypted" or "AllowUnencrypted"
    }), null)
    subnets = optional(map(object({
      address_prefixes                          = list(string)
      service_endpoints                         = optional(list(string), [])
      private_endpoint_network_policies         = optional(string, "Disabled")
      private_link_service_network_policies_enabled = optional(bool, false)
      delegation = optional(object({
        name = string
        service_delegation = object({
          name    = string
          actions = optional(list(string), [])
        })
      }), null)
    })), {})
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources. Merged with default tags."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------
# Optional: Internal utility module variables
# Uncomment to enable naming, tagging, diagnostics, budget,
# and IPAM enforcement within this module.
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

# variable "ipam_config" {
#   description = "Configuration for the az-ipam module. Set to null to use explicit address spaces."
#   type = object({
#     root_cidrs     = list(string)
#     reserved_cidrs = optional(list(string), [])
#     allocations    = any
#   })
#   default = null
# }
