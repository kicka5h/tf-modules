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
