mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  application_gateways = {
    web = {
      name = "appgw-web"
      sku = {
        name     = "Standard_v2"
        tier     = "Standard_v2"
        capacity = 2
      }
      gateway_ip_configuration = {
        name      = "gateway-ip-config"
        subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/appgw-subnet"
      }
      frontend_ip_configurations = {
        public = {
          name                 = "fe-ip-public"
          public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/pip-appgw"
        }
      }
      frontend_ports = {
        http = {
          name = "fe-port-80"
          port = 80
        }
      }
      backend_address_pools = {
        default = {
          name         = "be-pool-default"
          ip_addresses = ["10.0.1.4", "10.0.1.5"]
        }
      }
      backend_http_settings = {
        default = {
          name     = "be-http-settings-default"
          port     = 80
          protocol = "Http"
        }
      }
      http_listeners = {
        http = {
          name                           = "listener-http"
          frontend_ip_configuration_name = "fe-ip-public"
          frontend_port_name             = "fe-port-80"
          protocol                       = "Http"
        }
      }
      request_routing_rules = {
        basic = {
          name                       = "rule-basic"
          rule_type                  = "Basic"
          http_listener_name         = "listener-http"
          backend_address_pool_name  = "be-pool-default"
          backend_http_settings_name = "be-http-settings-default"
          priority                   = 100
        }
      }
    }
  }
}

run "creates_application_gateway" {
  command = plan

  assert {
    condition     = length(azurerm_application_gateway.this) == 1
    error_message = "Expected 1 application gateway"
  }

  assert {
    condition     = azurerm_application_gateway.this["web"].name == "appgw-web"
    error_message = "Expected application gateway name to be appgw-web"
  }
}

run "sets_location_and_resource_group" {
  command = plan

  assert {
    condition     = azurerm_application_gateway.this["web"].location == "eastus2"
    error_message = "Expected location to be eastus2"
  }

  assert {
    condition     = azurerm_application_gateway.this["web"].resource_group_name == "rg-test"
    error_message = "Expected resource group to be rg-test"
  }
}

run "sets_sku" {
  command = plan

  assert {
    condition     = azurerm_application_gateway.this["web"].sku[0].name == "Standard_v2"
    error_message = "Expected sku name to be Standard_v2"
  }

  assert {
    condition     = azurerm_application_gateway.this["web"].sku[0].tier == "Standard_v2"
    error_message = "Expected sku tier to be Standard_v2"
  }

  assert {
    condition     = azurerm_application_gateway.this["web"].sku[0].capacity == 2
    error_message = "Expected sku capacity to be 2"
  }
}
