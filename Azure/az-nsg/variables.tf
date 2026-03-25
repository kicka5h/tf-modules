variable "resource_group_name" {
  description = "Name of the resource group to create NSGs in"
  type        = string
}

variable "location" {
  description = "Azure region for all NSGs"
  type        = string
}

variable "nsgs" {
  description = "Map of network security groups to create. Key is a logical name, value defines the NSG, its rules, and subnet associations."
  type = map(object({
    name = string
    rules = optional(map(object({
      priority                                   = number
      direction                                  = string # "Inbound", "Outbound"
      access                                     = string # "Allow", "Deny"
      protocol                                   = string # "Tcp", "Udp", "Icmp", "*"
      source_port_range                          = optional(string, "*")
      source_port_ranges                         = optional(list(string), null)
      destination_port_range                     = optional(string, null)
      destination_port_ranges                    = optional(list(string), null)
      source_address_prefix                      = optional(string, null)
      source_address_prefixes                    = optional(list(string), null)
      destination_address_prefix                 = optional(string, null)
      destination_address_prefixes               = optional(list(string), null)
      source_application_security_group_ids      = optional(list(string), null)
      destination_application_security_group_ids = optional(list(string), null)
      description                                = optional(string, null)
    })), {})
    subnet_ids = optional(list(string), [])
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for nsg_key, nsg in var.nsgs : [
        for r_key, r in nsg.rules :
        r.priority >= 200
      ]
    ]))
    error_message = "User-defined rule priorities must be >= 200. Priorities 100-199 are reserved for module-enforced blocklist rules."
  }

  validation {
    condition = alltrue(flatten([
      for nsg_key, nsg in var.nsgs : [
        for r_key, r in nsg.rules :
        contains(["Inbound", "Outbound"], r.direction)
      ]
    ]))
    error_message = "Each rule must have direction set to one of: Inbound, Outbound."
  }

  validation {
    condition = alltrue(flatten([
      for nsg_key, nsg in var.nsgs : [
        for r_key, r in nsg.rules :
        contains(["Allow", "Deny"], r.access)
      ]
    ]))
    error_message = "Each rule must have access set to one of: Allow, Deny."
  }

  validation {
    condition = alltrue(flatten([
      for nsg_key, nsg in var.nsgs : [
        for r_key, r in nsg.rules :
        contains(["Tcp", "Udp", "Icmp", "*"], r.protocol)
      ]
    ]))
    error_message = "Each rule must have protocol set to one of: Tcp, Udp, Icmp, *."
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
