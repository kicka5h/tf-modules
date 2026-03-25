variable "resource_group_name" {
  description = "Name of the resource group to create Key Vaults in"
  type        = string
}

variable "location" {
  description = "Azure region for all Key Vaults"
  type        = string
}

variable "key_vaults" {
  description = "Map of Key Vaults to create. Key is a logical name, value defines the vault configuration."
  type = map(object({
    name = string
    # Enforce: premium SKU for HSM-backed keys
    sku_name = optional(string, "premium")
    # Enforce: soft delete (always on in Azure, but set retention)
    soft_delete_retention_days = optional(number, 90)
    # Enforce: purge protection
    purge_protection_enabled = optional(bool, true)
    # Enforce: RBAC authorization by default (preferred over access policies)
    enable_rbac_authorization = optional(bool, true)
    # Enforce: no public network access
    public_network_access_enabled = optional(bool, false)
    # Enforce: enabled for deployment, disk encryption, template deployment
    enabled_for_deployment          = optional(bool, true)
    enabled_for_disk_encryption     = optional(bool, true)
    enabled_for_template_deployment = optional(bool, true)
    # Network ACLs
    network_acls = optional(object({
      default_action             = optional(string, "Deny")
      bypass                     = optional(string, "AzureServices")
      ip_rules                   = optional(list(string), [])
      virtual_network_subnet_ids = optional(list(string), [])
    }), null)
    # Access policies (only used when enable_rbac_authorization = false)
    access_policies = optional(map(object({
      object_id               = string
      tenant_id               = optional(string, null) # defaults to current tenant
      key_permissions         = optional(list(string), [])
      secret_permissions      = optional(list(string), [])
      certificate_permissions = optional(list(string), [])
      storage_permissions     = optional(list(string), [])
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, kv in var.key_vaults :
      kv.purge_protection_enabled == true
    ])
    error_message = "Purge protection must be enabled on all Key Vaults (purge_protection_enabled = true)."
  }

  validation {
    condition = alltrue([
      for k, kv in var.key_vaults :
      contains(["standard", "premium"], kv.sku_name)
    ])
    error_message = "Each Key Vault must have sku_name set to one of: standard, premium."
  }

  validation {
    condition = alltrue([
      for k, kv in var.key_vaults :
      kv.public_network_access_enabled == false
    ])
    error_message = "Public network access must be disabled on all Key Vaults (public_network_access_enabled = false)."
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
