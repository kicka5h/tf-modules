locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)

  # Split web apps by OS type
  linux_apps = {
    for k, app in var.web_apps : k => app
    if app.os_type == "linux"
  }

  windows_apps = {
    for k, app in var.web_apps : k => app
    if app.os_type == "windows"
  }
}

# --- App Service Plans ---

resource "azurerm_service_plan" "this" {
  for_each = var.service_plans

  name                   = each.value.name
  location               = var.location
  resource_group_name    = var.resource_group_name
  os_type                = each.value.os_type
  sku_name               = each.value.sku_name
  worker_count           = each.value.worker_count
  zone_balancing_enabled = each.value.zone_balancing_enabled
  tags                   = merge(local.tags, each.value.tags)
}

# --- Linux Web Apps ---

resource "azurerm_linux_web_app" "this" {
  for_each = local.linux_apps

  name                          = each.value.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  service_plan_id               = azurerm_service_plan.this[each.value.service_plan_key].id
  https_only                    = each.value.https_only
  public_network_access_enabled = each.value.public_network_access_enabled
  virtual_network_subnet_id     = each.value.virtual_network_subnet_id
  app_settings                  = each.value.app_settings
  tags                          = merge(local.tags, each.value.tags)

  site_config {
    always_on                         = each.value.site_config.always_on
    minimum_tls_version               = each.value.site_config.minimum_tls_version
    ftps_state                        = each.value.site_config.ftps_state
    remote_debugging_enabled          = each.value.site_config.remote_debugging_enabled
    health_check_path                 = each.value.site_config.health_check_path
    health_check_eviction_time_in_min = each.value.site_config.health_check_eviction_time_in_min
    worker_count                      = each.value.site_config.worker_count
    ip_restriction_default_action     = each.value.site_config.ip_restriction_default_action

    dynamic "application_stack" {
      for_each = each.value.site_config.application_stack_linux != null ? [each.value.site_config.application_stack_linux] : []
      content {
        docker_image_name   = application_stack.value.docker_image_name
        docker_registry_url = application_stack.value.docker_registry_url
        dotnet_version      = application_stack.value.dotnet_version
        java_version        = application_stack.value.java_version
        java_server         = application_stack.value.java_server
        java_server_version = application_stack.value.java_server_version
        node_version        = application_stack.value.node_version
        php_version         = application_stack.value.php_version
        python_version      = application_stack.value.python_version
        ruby_version        = application_stack.value.ruby_version
        go_version          = application_stack.value.go_version
      }
    }
  }

  dynamic "connection_string" {
    for_each = each.value.connection_strings
    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "sticky_settings" {
    for_each = each.value.sticky_settings != null ? [each.value.sticky_settings] : []
    content {
      app_setting_names       = sticky_settings.value.app_setting_names
      connection_string_names = sticky_settings.value.connection_string_names
    }
  }

  dynamic "logs" {
    for_each = each.value.logs != null ? [each.value.logs] : []
    content {
      detailed_error_messages = logs.value.detailed_error_messages
      failed_request_tracing  = logs.value.failed_request_tracing

      dynamic "http_logs" {
        for_each = logs.value.http_logs != null ? [logs.value.http_logs] : []
        content {
          file_system {
            retention_in_days = http_logs.value.retention_in_days
            retention_in_mb   = http_logs.value.retention_in_mb
          }
        }
      }
    }
  }
}

# --- Windows Web Apps ---

resource "azurerm_windows_web_app" "this" {
  for_each = local.windows_apps

  name                          = each.value.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  service_plan_id               = azurerm_service_plan.this[each.value.service_plan_key].id
  https_only                    = each.value.https_only
  public_network_access_enabled = each.value.public_network_access_enabled
  virtual_network_subnet_id     = each.value.virtual_network_subnet_id
  app_settings                  = each.value.app_settings
  tags                          = merge(local.tags, each.value.tags)

  site_config {
    always_on                         = each.value.site_config.always_on
    minimum_tls_version               = each.value.site_config.minimum_tls_version
    ftps_state                        = each.value.site_config.ftps_state
    remote_debugging_enabled          = each.value.site_config.remote_debugging_enabled
    health_check_path                 = each.value.site_config.health_check_path
    health_check_eviction_time_in_min = each.value.site_config.health_check_eviction_time_in_min
    worker_count                      = each.value.site_config.worker_count
    ip_restriction_default_action     = each.value.site_config.ip_restriction_default_action

    dynamic "application_stack" {
      for_each = each.value.site_config.application_stack_windows != null ? [each.value.site_config.application_stack_windows] : []
      content {
        current_stack          = application_stack.value.current_stack
        dotnet_version         = application_stack.value.dotnet_version
        java_version           = application_stack.value.java_version
        java_container         = application_stack.value.java_container
        java_container_version = application_stack.value.java_container_version
        node_version           = application_stack.value.node_version
        php_version            = application_stack.value.php_version
        python                 = application_stack.value.python
      }
    }
  }

  dynamic "connection_string" {
    for_each = each.value.connection_strings
    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "sticky_settings" {
    for_each = each.value.sticky_settings != null ? [each.value.sticky_settings] : []
    content {
      app_setting_names       = sticky_settings.value.app_setting_names
      connection_string_names = sticky_settings.value.connection_string_names
    }
  }

  dynamic "logs" {
    for_each = each.value.logs != null ? [each.value.logs] : []
    content {
      detailed_error_messages = logs.value.detailed_error_messages
      failed_request_tracing  = logs.value.failed_request_tracing

      dynamic "http_logs" {
        for_each = logs.value.http_logs != null ? [logs.value.http_logs] : []
        content {
          file_system {
            retention_in_days = http_logs.value.retention_in_days
            retention_in_mb   = http_logs.value.retention_in_mb
          }
        }
      }
    }
  }
}

# =================================================================
# Optional: Internal utility module integration
# Uncomment the blocks below to enable az-naming, az-tagging,
# az-diagnostics, and az-budget within this module.
# =================================================================

# --- az-naming: generate compliant resource names ---
# module "naming" {
#   count   = var.naming_config != null ? 1 : 0
#   source  = "github.com/<org>/tf-modules//Azure/az-naming"
#
#   environment = var.naming_config.environment
#   region      = var.naming_config.region
#   workload    = var.naming_config.workload
# }

# --- az-tagging: enforce standard tags ---
# module "tagging" {
#   count   = var.tagging_config != null ? 1 : 0
#   source  = "github.com/<org>/tf-modules//Azure/az-tagging"
#
#   environment         = var.tagging_config.environment
#   owner               = var.tagging_config.owner
#   cost_center         = var.tagging_config.cost_center
#   project             = var.tagging_config.project
#   data_classification = var.tagging_config.data_classification
# }

# --- az-diagnostics: send web app metrics/logs to Log Analytics ---
# module "diagnostics" {
#   source   = "github.com/<org>/tf-modules//Azure/az-diagnostics"
#   for_each = var.diagnostics_config != null ? merge(
#     azurerm_linux_web_app.this,
#     azurerm_windows_web_app.this
#   ) : {}
#
#   target_resource_id         = each.value.id
#   log_analytics_workspace_id = var.diagnostics_config.log_analytics_workspace_id
#   storage_account_id         = var.diagnostics_config.storage_account_id
# }

# --- az-budget: apply budget controls ---
# module "budget" {
#   count  = var.budget_config != null ? 1 : 0
#   source = "github.com/<org>/tf-modules//Azure/az-budget"
#
#   amount            = var.budget_config.amount
#   resource_group_id = var.budget_config.resource_group_id
#   start_date        = var.budget_config.start_date
#   contact_emails    = var.budget_config.contact_emails
# }
