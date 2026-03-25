mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  public_ips = {
    web = {
      name              = "pip-web"
      domain_name_label = "myapp-web"
      zones             = ["1", "2", "3"]
    }
    api = {
      name                    = "pip-api"
      idle_timeout_in_minutes = 10
    }
  }
}

run "public_ips_are_created" {
  command = plan

  assert {
    condition     = length(azurerm_public_ip.this) == 2
    error_message = "Expected two public IPs"
  }
}

run "defaults_are_applied" {
  command = plan

  assert {
    condition     = azurerm_public_ip.this["web"].sku == "Standard"
    error_message = "Expected default sku of Standard"
  }

  assert {
    condition     = azurerm_public_ip.this["web"].allocation_method == "Static"
    error_message = "Expected default allocation_method of Static"
  }

  assert {
    condition     = azurerm_public_ip.this["web"].sku_tier == "Regional"
    error_message = "Expected default sku_tier of Regional"
  }

  assert {
    condition     = azurerm_public_ip.this["web"].ip_version == "IPv4"
    error_message = "Expected default ip_version of IPv4"
  }

  assert {
    condition     = azurerm_public_ip.this["web"].idle_timeout_in_minutes == 4
    error_message = "Expected default idle_timeout_in_minutes of 4"
  }
}

run "explicit_values_are_honoured" {
  command = plan

  assert {
    condition     = azurerm_public_ip.this["web"].domain_name_label == "myapp-web"
    error_message = "Expected domain_name_label to be set"
  }

  assert {
    condition     = azurerm_public_ip.this["api"].idle_timeout_in_minutes == 10
    error_message = "Expected idle_timeout_in_minutes to be 10"
  }
}

run "prefix_is_created" {
  command = plan

  variables {
    public_ip_prefixes = {
      main = {
        name          = "ippre-main"
        prefix_length = 28
      }
    }
  }

  assert {
    condition     = length(azurerm_public_ip_prefix.this) == 1
    error_message = "Expected one public IP prefix"
  }

  assert {
    condition     = azurerm_public_ip_prefix.this["main"].prefix_length == 28
    error_message = "Expected prefix_length of 28"
  }
}
