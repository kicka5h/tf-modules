resource_group_name = "rg-app-service-prod"
location            = "eastus2"

service_plans = {
  linux_plan = {
    name     = "plan-linux-prod"
    os_type  = "Linux"
    sku_name = "P1v3"
  }
  windows_plan = {
    name     = "plan-windows-prod"
    os_type  = "Windows"
    sku_name = "S1"
  }
}

web_apps = {
  node_api = {
    name             = "app-node-api-prod"
    service_plan_key = "linux_plan"
    os_type          = "linux"
    app_settings = {
      "NODE_ENV" = "production"
    }
    site_config = {
      health_check_path = "/health"
      application_stack_linux = {
        node_version = "20-lts"
      }
    }
    logs = {
      http_logs = {
        retention_in_days = 30
        retention_in_mb   = 100
      }
    }
  }

  python_worker = {
    name                      = "app-python-worker-prod"
    service_plan_key          = "linux_plan"
    os_type                   = "linux"
    virtual_network_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-prod/subnets/snet-apps"
    site_config = {
      application_stack_linux = {
        python_version = "3.12"
      }
    }
  }

  dotnet_web = {
    name             = "app-dotnet-web-prod"
    service_plan_key = "windows_plan"
    os_type          = "windows"
    connection_strings = {
      db = {
        type  = "SQLAzure"
        value = "Server=tcp:sql-prod.database.windows.net;Database=mydb;"
      }
    }
    site_config = {
      application_stack_windows = {
        current_stack  = "dotnet"
        dotnet_version = "v8.0"
      }
    }
    sticky_settings = {
      connection_string_names = ["db"]
    }
    logs = {
      http_logs = {
        retention_in_days = 14
        retention_in_mb   = 100
      }
    }
  }
}

tags = {
  Environment = "production"
  Team        = "platform"
}
