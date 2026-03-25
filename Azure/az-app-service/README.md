# az-app-service

Creates and manages Azure App Service plans and web apps (Linux and Windows) with enforced security defaults, managed identity, VNet integration, application stacks, logging, and connection string configuration.

## Usage

```hcl
module "app_service" {
  source              = "../az-app-service"
  resource_group_name = "rg-app-service-prod"
  location            = "eastus2"

  service_plans = {
    linux_plan = {
      name     = "plan-linux-prod"
      os_type  = "Linux"
      sku_name = "P1v3"
    }
  }

  web_apps = {
    api = {
      name             = "app-api-prod"
      service_plan_key = "linux_plan"
      os_type          = "linux"
      site_config = {
        application_stack_linux = {
          node_version = "20-lts"
        }
      }
    }
  }

  tags = {
    Environment = "production"
  }
}
```

## Configuration Reference

### Service Plans

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Plan name | `service_plans.<key>.name` | Any valid App Service plan name |
| OS type | `service_plans.<key>.os_type` | `"Linux"`, `"Windows"` |
| SKU | `service_plans.<key>.sku_name` | `"F1"`, `"B1"`, `"S1"`, `"P1v3"`, etc. |
| Worker count | `service_plans.<key>.worker_count` | Number (default: `null` — provider default) |
| Zone balancing | `service_plans.<key>.zone_balancing_enabled` | `true`, `false` (default: `false`) |
| Tags | `service_plans.<key>.tags` | `map(string)`, merged with module-level tags |

### Web Apps

| What | Variable Path | Valid Values |
| --- | --- | --- |
| App name | `web_apps.<key>.name` | Any valid web app name |
| Service plan reference | `web_apps.<key>.service_plan_key` | Key from `service_plans` map |
| OS type | `web_apps.<key>.os_type` | `"linux"`, `"windows"` |
| HTTPS only | `web_apps.<key>.https_only` | `true` (enforced, validation rejects `false`) |
| Public network access | `web_apps.<key>.public_network_access_enabled` | `false` (enforced, validation rejects `true`) |
| VNet subnet ID | `web_apps.<key>.virtual_network_subnet_id` | Subnet resource ID or `null` |
| App settings | `web_apps.<key>.app_settings` | `map(string)` |
| Tags | `web_apps.<key>.tags` | `map(string)`, merged with module-level tags |

### Site Config

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Always on | `web_apps.<key>.site_config.always_on` | `true` (default, enforced) |
| Minimum TLS version | `web_apps.<key>.site_config.minimum_tls_version` | `"1.2"` (enforced, validation rejects other values) |
| FTPS state | `web_apps.<key>.site_config.ftps_state` | `"Disabled"` (enforced, validation rejects other values) |
| Remote debugging | `web_apps.<key>.site_config.remote_debugging_enabled` | `false` (enforced, validation rejects `true`) |
| Health check path | `web_apps.<key>.site_config.health_check_path` | URL path or `null` |
| Health check eviction time | `web_apps.<key>.site_config.health_check_eviction_time_in_min` | Number or `null` |
| Worker count | `web_apps.<key>.site_config.worker_count` | Number or `null` |
| IP restriction default action | `web_apps.<key>.site_config.ip_restriction_default_action` | `"Allow"`, `"Deny"`, or `null` |

### Application Stack (Linux)

| What | Variable Path |
| --- | --- |
| Docker image | `web_apps.<key>.site_config.application_stack_linux.docker_image_name` |
| Docker registry URL | `web_apps.<key>.site_config.application_stack_linux.docker_registry_url` |
| .NET version | `web_apps.<key>.site_config.application_stack_linux.dotnet_version` |
| Java version | `web_apps.<key>.site_config.application_stack_linux.java_version` |
| Java server | `web_apps.<key>.site_config.application_stack_linux.java_server` |
| Java server version | `web_apps.<key>.site_config.application_stack_linux.java_server_version` |
| Node.js version | `web_apps.<key>.site_config.application_stack_linux.node_version` |
| PHP version | `web_apps.<key>.site_config.application_stack_linux.php_version` |
| Python version | `web_apps.<key>.site_config.application_stack_linux.python_version` |
| Ruby version | `web_apps.<key>.site_config.application_stack_linux.ruby_version` |
| Go version | `web_apps.<key>.site_config.application_stack_linux.go_version` |

### Application Stack (Windows)

| What | Variable Path |
| --- | --- |
| Current stack | `web_apps.<key>.site_config.application_stack_windows.current_stack` |
| .NET version | `web_apps.<key>.site_config.application_stack_windows.dotnet_version` |
| Java version | `web_apps.<key>.site_config.application_stack_windows.java_version` |
| Java container | `web_apps.<key>.site_config.application_stack_windows.java_container` |
| Java container version | `web_apps.<key>.site_config.application_stack_windows.java_container_version` |
| Node.js version | `web_apps.<key>.site_config.application_stack_windows.node_version` |
| PHP version | `web_apps.<key>.site_config.application_stack_windows.php_version` |
| Python | `web_apps.<key>.site_config.application_stack_windows.python` |

### Identity

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Identity type | `web_apps.<key>.identity.type` | `"SystemAssigned"`, `"UserAssigned"`, `"SystemAssigned, UserAssigned"` (default: `"SystemAssigned"`) |
| Identity IDs | `web_apps.<key>.identity.identity_ids` | List of user-assigned identity resource IDs |

### Connection Strings

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Type | `web_apps.<key>.connection_strings.<name>.type` | `"SQLServer"`, `"SQLAzure"`, `"MySQL"`, `"PostgreSQL"`, `"Custom"`, etc. |
| Value | `web_apps.<key>.connection_strings.<name>.value` | Connection string value |

### Sticky Settings

| What | Variable Path | Valid Values |
| --- | --- | --- |
| App setting names | `web_apps.<key>.sticky_settings.app_setting_names` | List of app setting names |
| Connection string names | `web_apps.<key>.sticky_settings.connection_string_names` | List of connection string names |

### Logging

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Detailed error messages | `web_apps.<key>.logs.detailed_error_messages` | `true`, `false` (default: `true`) |
| Failed request tracing | `web_apps.<key>.logs.failed_request_tracing` | `true`, `false` (default: `true`) |
| HTTP log retention days | `web_apps.<key>.logs.http_logs.retention_in_days` | Number (default: `7`) |
| HTTP log retention MB | `web_apps.<key>.logs.http_logs.retention_in_mb` | Number (default: `100`) |

### Tags

| What | Variable | Notes |
| --- | --- | --- |
| Custom tags | `tags` | `map(string)`, merged with default tags |
| Per-plan tags | `service_plans.<key>.tags` | `map(string)`, merged with module-level tags |
| Per-app tags | `web_apps.<key>.tags` | `map(string)`, merged with module-level tags |

## Enforced Policies

- **HTTPS only**: Validation rejects any web app with `https_only = false`. All traffic must use HTTPS.
- **TLS 1.2 minimum**: Validation rejects any web app with `minimum_tls_version` other than `"1.2"`.
- **FTP disabled**: Validation rejects any web app with `ftps_state` other than `"Disabled"`. Use deployment slots or CI/CD for deployments.
- **Remote debugging disabled**: Validation rejects any web app with `remote_debugging_enabled = true`.
- **Public network access disabled**: Validation rejects any web app with `public_network_access_enabled = true`. Web apps must be accessed through private endpoints or VNet integration.
- **Always on**: Web apps default to `always_on = true` to prevent cold starts.
- **System-assigned managed identity**: Web apps default to `SystemAssigned` identity for secure Azure service authentication.
- **Default tags**: `Terraform = "true"` is always applied and merged with caller-provided tags.
- **Deletion protection**: OPA policy denies deletion or replacement of service plans and web apps in CI/CD pipelines.
