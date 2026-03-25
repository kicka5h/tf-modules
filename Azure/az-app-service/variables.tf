variable "resource_group_name" {
  description = "Name of the resource group to create App Service resources in"
  type        = string
}

variable "location" {
  description = "Azure region for all App Service resources"
  type        = string
}

variable "service_plans" {
  description = "Map of App Service plans to create. Key is a logical name, value defines the plan configuration."
  type = map(object({
    name                   = string
    os_type                = string # "Linux" or "Windows"
    sku_name               = string # e.g., "P1v3", "S1", "B1", "F1"
    worker_count           = optional(number, null)
    zone_balancing_enabled = optional(bool, false)
    tags                   = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, sp in var.service_plans :
      contains(["Linux", "Windows"], sp.os_type)
    ])
    error_message = "Each service plan must have os_type set to one of: Linux, Windows."
  }
}

variable "web_apps" {
  description = "Map of web apps to create. Key is a logical name, value defines the app configuration."
  type = map(object({
    name             = string
    service_plan_key = string # key into var.service_plans
    os_type          = string # "linux" or "windows" — determines which resource type to create
    # Enforce: HTTPS only
    https_only = optional(bool, true)
    # Enforce: public network access disabled
    public_network_access_enabled = optional(bool, false)
    # Enforce: managed identity
    identity = optional(object({
      type         = optional(string, "SystemAssigned")
      identity_ids = optional(list(string), [])
    }), { type = "SystemAssigned" })
    # VNet integration
    virtual_network_subnet_id = optional(string, null)
    # App settings
    app_settings = optional(map(string), {})
    # Connection strings
    connection_strings = optional(map(object({
      type  = string # "SQLServer", "SQLAzure", "MySQL", "PostgreSQL", "Custom", etc.
      value = string
    })), {})
    # Site config — shared between linux and windows
    site_config = optional(object({
      # Enforce: always on
      always_on = optional(bool, true)
      # Enforce: minimum TLS 1.2
      minimum_tls_version = optional(string, "1.2")
      # Enforce: FTP disabled
      ftps_state = optional(string, "Disabled") # "AllAllowed", "FtpsOnly", "Disabled"
      # Enforce: remote debugging off
      remote_debugging_enabled = optional(bool, false)
      # Health check
      health_check_path                 = optional(string, null)
      health_check_eviction_time_in_min = optional(number, null)
      # Scaling
      worker_count = optional(number, null)
      # IP restrictions
      ip_restriction_default_action = optional(string, null)
      # Application stack for Linux
      application_stack_linux = optional(object({
        docker_image_name   = optional(string, null)
        docker_registry_url = optional(string, null)
        dotnet_version      = optional(string, null)
        java_version        = optional(string, null)
        java_server         = optional(string, null)
        java_server_version = optional(string, null)
        node_version        = optional(string, null)
        php_version         = optional(string, null)
        python_version      = optional(string, null)
        ruby_version        = optional(string, null)
        go_version          = optional(string, null)
      }), null)
      # Application stack for Windows
      application_stack_windows = optional(object({
        current_stack          = optional(string, null)
        dotnet_version         = optional(string, null)
        java_version           = optional(string, null)
        java_container         = optional(string, null)
        java_container_version = optional(string, null)
        node_version           = optional(string, null)
        php_version            = optional(string, null)
        python                 = optional(bool, null)
      }), null)
    }), {})
    # Sticky settings (slot settings)
    sticky_settings = optional(object({
      app_setting_names       = optional(list(string), [])
      connection_string_names = optional(list(string), [])
    }), null)
    # Logging
    logs = optional(object({
      detailed_error_messages = optional(bool, true)
      failed_request_tracing  = optional(bool, true)
      http_logs = optional(object({
        retention_in_days = optional(number, 7)
        retention_in_mb   = optional(number, 100)
      }), null)
    }), null)
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, app in var.web_apps :
      contains(["linux", "windows"], app.os_type)
    ])
    error_message = "Each web app must have os_type set to one of: linux, windows."
  }

  validation {
    condition = alltrue([
      for k, app in var.web_apps :
      app.https_only == true
    ])
    error_message = "All web apps must enforce HTTPS only (https_only = true)."
  }

  validation {
    condition = alltrue([
      for k, app in var.web_apps :
      app.site_config.minimum_tls_version == "1.2"
    ])
    error_message = "All web apps must use minimum TLS version 1.2."
  }

  validation {
    condition = alltrue([
      for k, app in var.web_apps :
      app.site_config.ftps_state == "Disabled"
    ])
    error_message = "FTP must be disabled on all web apps (ftps_state = Disabled)."
  }

  validation {
    condition = alltrue([
      for k, app in var.web_apps :
      app.site_config.remote_debugging_enabled == false
    ])
    error_message = "Remote debugging must be disabled on all web apps."
  }

  validation {
    condition = alltrue([
      for k, app in var.web_apps :
      app.public_network_access_enabled == false
    ])
    error_message = "Public network access must be disabled on all web apps (public_network_access_enabled = false)."
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
