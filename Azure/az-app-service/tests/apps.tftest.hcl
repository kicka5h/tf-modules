mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  service_plans = {
    linux_plan = {
      name     = "plan-linux-test"
      os_type  = "Linux"
      sku_name = "P1v3"
    }
    windows_plan = {
      name     = "plan-windows-test"
      os_type  = "Windows"
      sku_name = "S1"
    }
  }

  web_apps = {
    node_app = {
      name             = "app-node-test"
      service_plan_key = "linux_plan"
      os_type          = "linux"
      site_config = {
        application_stack_linux = {
          node_version = "20-lts"
        }
      }
    }
    dotnet_app = {
      name             = "app-dotnet-test"
      service_plan_key = "windows_plan"
      os_type          = "windows"
      site_config = {
        application_stack_windows = {
          current_stack  = "dotnet"
          dotnet_version = "v8.0"
        }
      }
    }
  }
}

run "creates_service_plans" {
  command = plan

  assert {
    condition     = length(azurerm_service_plan.this) == 2
    error_message = "Expected 2 service plans"
  }

  assert {
    condition     = azurerm_service_plan.this["linux_plan"].name == "plan-linux-test"
    error_message = "Expected Linux plan name to be plan-linux-test"
  }

  assert {
    condition     = azurerm_service_plan.this["linux_plan"].os_type == "Linux"
    error_message = "Expected Linux plan os_type to be Linux"
  }

  assert {
    condition     = azurerm_service_plan.this["linux_plan"].sku_name == "P1v3"
    error_message = "Expected Linux plan SKU to be P1v3"
  }

  assert {
    condition     = azurerm_service_plan.this["windows_plan"].name == "plan-windows-test"
    error_message = "Expected Windows plan name to be plan-windows-test"
  }

  assert {
    condition     = azurerm_service_plan.this["windows_plan"].os_type == "Windows"
    error_message = "Expected Windows plan os_type to be Windows"
  }
}

run "creates_linux_web_app" {
  command = plan

  assert {
    condition     = length(azurerm_linux_web_app.this) == 1
    error_message = "Expected 1 Linux web app"
  }

  assert {
    condition     = azurerm_linux_web_app.this["node_app"].name == "app-node-test"
    error_message = "Expected Linux app name to be app-node-test"
  }

  assert {
    condition     = azurerm_linux_web_app.this["node_app"].https_only == true
    error_message = "Expected HTTPS only to be enforced"
  }
}

run "creates_windows_web_app" {
  command = plan

  assert {
    condition     = length(azurerm_windows_web_app.this) == 1
    error_message = "Expected 1 Windows web app"
  }

  assert {
    condition     = azurerm_windows_web_app.this["dotnet_app"].name == "app-dotnet-test"
    error_message = "Expected Windows app name to be app-dotnet-test"
  }

  assert {
    condition     = azurerm_windows_web_app.this["dotnet_app"].https_only == true
    error_message = "Expected HTTPS only to be enforced"
  }
}

run "sets_location_and_resource_group" {
  command = plan

  assert {
    condition     = azurerm_service_plan.this["linux_plan"].location == "eastus2"
    error_message = "Expected location to be eastus2"
  }

  assert {
    condition     = azurerm_service_plan.this["linux_plan"].resource_group_name == "rg-test"
    error_message = "Expected resource group to be rg-test"
  }

  assert {
    condition     = azurerm_linux_web_app.this["node_app"].location == "eastus2"
    error_message = "Expected Linux app location to be eastus2"
  }

  assert {
    condition     = azurerm_linux_web_app.this["node_app"].resource_group_name == "rg-test"
    error_message = "Expected Linux app resource group to be rg-test"
  }
}
