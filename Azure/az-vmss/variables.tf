variable "resource_group_name" {
  description = "Name of the resource group to create scale sets in"
  type        = string
}

variable "location" {
  description = "Azure region for all scale sets"
  type        = string
}

variable "scale_sets" {
  description = "Map of Virtual Machine Scale Sets to create. Key is a logical name, value defines the VMSS configuration."
  type = map(object({
    name      = string
    os_type   = string # "linux" or "windows"
    sku       = string
    instances = optional(number, 2)
    zones     = optional(list(string), [])
    admin_username = string
    admin_password = optional(string, null)
    admin_ssh_key = optional(object({
      public_key = string
    }), null)
    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
    os_disk = optional(object({
      caching                = optional(string, "ReadWrite")
      storage_account_type   = optional(string, "Premium_LRS")
      disk_size_gb           = optional(number, null)
      disk_encryption_set_id = optional(string, null)
    }), {})
    network_interface = object({
      name                          = string
      primary                       = optional(bool, true)
      subnet_id                     = string
      enable_accelerated_networking = optional(bool, true)
    })
    boot_diagnostics = optional(object({
      storage_account_uri = optional(string, null)
    }), {})
    identity = optional(object({
      type         = optional(string, "SystemAssigned")
      identity_ids = optional(list(string), [])
    }), { type = "SystemAssigned" })
    secure_boot_enabled        = optional(bool, true)
    vtpm_enabled               = optional(bool, true)
    encryption_at_host_enabled = optional(bool, false)
    zone_balance               = optional(bool, true)
    upgrade_mode               = optional(string, "Rolling")
    rolling_upgrade_policy = optional(object({
      max_batch_instance_percent              = optional(number, 20)
      max_unhealthy_instance_percent          = optional(number, 20)
      max_unhealthy_upgraded_instance_percent = optional(number, 20)
      pause_time_between_batches              = optional(string, "PT2S")
    }), {})
    health_probe_id = optional(string, null)
    automatic_instance_repair = optional(object({
      enabled      = optional(bool, true)
      grace_period = optional(string, "PT30M")
    }), null)
    automatic_os_upgrade_policy = optional(object({
      disable_automatic_rollback  = optional(bool, false)
      enable_automatic_os_upgrade = optional(bool, true)
    }), null)
    data_disks = optional(map(object({
      storage_account_type   = optional(string, "Premium_LRS")
      disk_size_gb           = number
      caching                = optional(string, "ReadOnly")
      lun                    = number
      create_option          = optional(string, "Empty")
      disk_encryption_set_id = optional(string, null)
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, ss in var.scale_sets :
      contains(["linux", "windows"], ss.os_type)
    ])
    error_message = "Each scale set must have os_type set to one of: linux, windows."
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
