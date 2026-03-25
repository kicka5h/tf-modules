variable "resource_group_name" {
  description = "Name of the resource group to create NAT gateways in"
  type        = string
}

variable "location" {
  description = "Azure region for all NAT gateways"
  type        = string
}

variable "nat_gateways" {
  description = "Map of NAT gateways to create. Key is a logical name, value defines the gateway and its associations."
  type = map(object({
    name                    = string
    sku_name                = optional(string, "Standard")
    idle_timeout_in_minutes = optional(number, 4)
    zones                   = optional(list(string), [])
    public_ip_ids           = optional(list(string), [])
    public_ip_prefix_ids    = optional(list(string), [])
    subnet_ids              = optional(list(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for gw_key, gw in var.nat_gateways :
      contains(["Standard"], gw.sku_name)
    ])
    error_message = "Each NAT gateway must have sku_name set to: Standard."
  }

  validation {
    condition = alltrue([
      for gw_key, gw in var.nat_gateways :
      gw.idle_timeout_in_minutes >= 4 && gw.idle_timeout_in_minutes <= 120
    ])
    error_message = "Each NAT gateway idle_timeout_in_minutes must be between 4 and 120."
  }
}

variable "tags" {
  description = "Tags to apply to all resources. Merged with default tags."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------
# Optional: Internal utility module variables
# Uncomment to enable naming, tagging, and budget
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
