variable "resource_group_name" {
  description = "Name of the resource group to create load balancers in"
  type        = string
}

variable "location" {
  description = "Azure region for all load balancers"
  type        = string
}

variable "load_balancers" {
  description = "Map of load balancers to create. Key is a logical name, value defines the LB and its child resources."
  type = map(object({
    name     = string
    sku      = optional(string, "Standard")
    sku_tier = optional(string, "Regional")
    frontend_ip_configurations = map(object({
      name                          = string
      public_ip_address_id          = optional(string, null)
      subnet_id                     = optional(string, null)
      private_ip_address            = optional(string, null)
      private_ip_address_allocation = optional(string, "Dynamic")
      zones                         = optional(list(string), [])
    }))
    backend_pools = optional(map(object({
      name = string
    })), {})
    probes = optional(map(object({
      name                = string
      protocol            = string # "Http", "Https", "Tcp"
      port                = number
      request_path        = optional(string, null)
      interval_in_seconds = optional(number, 5)
      number_of_probes    = optional(number, 2)
    })), {})
    rules = optional(map(object({
      name                           = string
      protocol                       = string # "Tcp", "Udp", "All"
      frontend_port                  = number
      backend_port                   = number
      frontend_ip_configuration_name = string
      backend_address_pool_key       = string
      probe_key                      = string
      enable_floating_ip             = optional(bool, false)
      idle_timeout_in_minutes        = optional(number, 4)
      load_distribution              = optional(string, "Default")
      disable_outbound_snat          = optional(bool, false)
    })), {})
    nat_rules = optional(map(object({
      name                           = string
      protocol                       = string
      frontend_port                  = number
      backend_port                   = number
      frontend_ip_configuration_name = string
    })), {})
    outbound_rules = optional(map(object({
      name                           = string
      protocol                       = string # "Tcp", "Udp", "All"
      frontend_ip_configuration_name = string
      backend_address_pool_key       = string
      allocated_outbound_ports       = optional(number, null)
      idle_timeout_in_minutes        = optional(number, 4)
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for lb_key, lb in var.load_balancers :
      contains(["Basic", "Standard", "Gateway"], lb.sku)
    ])
    error_message = "Each load balancer must have sku set to one of: Basic, Standard, Gateway."
  }
}

variable "tags" {
  description = "Tags to apply to all resources. Merged with default tags."
  type        = map(string)
  default     = {}
}
