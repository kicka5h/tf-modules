variable "resource_group_name" {
  description = "Name of the resource group to create route tables in"
  type        = string
}

variable "location" {
  description = "Azure region for all route tables"
  type        = string
}

variable "route_tables" {
  description = "Map of route tables to create. Key is a logical name, value defines the route table and its routes."
  type = map(object({
    name                          = string
    bgp_route_propagation_enabled = optional(bool, true)
    routes = optional(map(object({
      address_prefix         = string
      next_hop_type          = string # "VirtualNetworkGateway", "VnetLocal", "Internet", "VirtualAppliance", "None"
      next_hop_in_ip_address = optional(string, null)
    })), {})
    subnet_ids = optional(list(string), [])
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for rt_key, rt in var.route_tables : [
        for r_key, r in rt.routes :
        contains(["VirtualNetworkGateway", "VnetLocal", "Internet", "VirtualAppliance", "None"], r.next_hop_type)
      ]
    ]))
    error_message = "Each route must have next_hop_type set to one of: VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance, None."
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
