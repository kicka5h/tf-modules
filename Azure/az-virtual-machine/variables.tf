variable "resource_group_name" {
  description = "Name of the resource group to create VMs in"
  type        = string
}

variable "location" {
  description = "Azure region for all VMs"
  type        = string
}

variable "virtual_machines" {
  description = "Map of virtual machines to create. Key is a logical name, value defines the VM configuration."
  type = map(object({
    name           = string
    os_type        = string # "linux" or "windows"
    size           = string # e.g., "Standard_D2s_v3"
    zone           = optional(string, null)
    admin_username = string
    admin_password = optional(string, null) # sensitive, required for windows
    admin_ssh_key = optional(object({
      public_key = string
    }), null)
    subnet_id                     = string
    private_ip_address            = optional(string, null)
    private_ip_address_allocation = optional(string, "Dynamic")
    # Enforce: no public IP by default
    public_ip_address_id = optional(string, null)
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
    # Enforce: boot diagnostics enabled by default
    boot_diagnostics = optional(object({
      storage_account_uri = optional(string, null)
    }), {})
    # Enforce: system-assigned managed identity by default
    identity = optional(object({
      type         = optional(string, "SystemAssigned")
      identity_ids = optional(list(string), [])
    }), { type = "SystemAssigned" })
    # Enforce: trusted launch
    secure_boot_enabled        = optional(bool, true)
    vtpm_enabled               = optional(bool, true)
    encryption_at_host_enabled = optional(bool, false)
    patch_mode                 = optional(string, null)
    data_disks = optional(map(object({
      name                   = string
      storage_account_type   = optional(string, "Premium_LRS")
      disk_size_gb           = number
      caching                = optional(string, "ReadOnly")
      lun                    = number
      create_option          = optional(string, "Empty")
      disk_encryption_set_id = optional(string, null)
    })), {})
    tags = optional(map(string), {}) # per-VM tags merged with module tags
  }))
  default  = {}
  sensitive = false

  validation {
    condition = alltrue([
      for k, vm in var.virtual_machines :
      contains(["linux", "windows"], vm.os_type)
    ])
    error_message = "Each VM must have os_type set to one of: linux, windows."
  }
}

variable "tags" {
  description = "Tags to apply to all resources. Merged with default tags."
  type        = map(string)
  default     = {}
}
