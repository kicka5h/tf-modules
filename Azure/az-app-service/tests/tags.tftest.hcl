mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  service_plans = {
    test = {
      name     = "plan-test"
      os_type  = "Linux"
      sku_name = "B1"
    }
  }

  web_apps = {
    test = {
      name             = "app-test"
      service_plan_key = "test"
      os_type          = "linux"
    }
  }
}

run "default_terraform_tag_is_applied_to_plan" {
  command = plan

  assert {
    condition     = azurerm_service_plan.this["test"].tags["Terraform"] == "true"
    error_message = "Expected default Terraform tag on service plan"
  }
}

run "default_terraform_tag_is_applied_to_app" {
  command = plan

  assert {
    condition     = azurerm_linux_web_app.this["test"].tags["Terraform"] == "true"
    error_message = "Expected default Terraform tag on web app"
  }
}

run "custom_tags_are_merged" {
  command = plan

  variables {
    tags = {
      environment = "dev"
    }
  }

  assert {
    condition     = azurerm_service_plan.this["test"].tags["Terraform"] == "true"
    error_message = "Default Terraform tag should still be present on plan"
  }

  assert {
    condition     = azurerm_service_plan.this["test"].tags["environment"] == "dev"
    error_message = "Custom tag should be present on plan"
  }

  assert {
    condition     = azurerm_linux_web_app.this["test"].tags["Terraform"] == "true"
    error_message = "Default Terraform tag should still be present on app"
  }

  assert {
    condition     = azurerm_linux_web_app.this["test"].tags["environment"] == "dev"
    error_message = "Custom tag should be present on app"
  }
}
