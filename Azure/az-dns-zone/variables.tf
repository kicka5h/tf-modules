variable "resource_group_name" {
  description = "Name of the resource group to create DNS zones in"
  type        = string
}

variable "dns_zones" {
  description = "Map of DNS zones to create. Key is a logical name, value defines the zone."
  type = map(object({
    name                     = string
    type                     = string # "public" or "private"
    vnet_links               = optional(map(object({
      virtual_network_id       = string
      registration_enabled     = optional(bool, false)
    })), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.dns_zones : contains(["public", "private"], v.type)])
    error_message = "Each dns_zones entry must have type set to \"public\" or \"private\"."
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
