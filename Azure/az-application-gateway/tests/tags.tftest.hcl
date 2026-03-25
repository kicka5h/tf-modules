mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  application_gateways = {
    test = {
      name = "appgw-test"
      sku = {
        name     = "Standard_v2"
        tier     = "Standard_v2"
        capacity = 1
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
          name = "be-pool-default"
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

run "default_terraform_tag_is_applied" {
  command = plan

  assert {
    condition     = azurerm_application_gateway.this["test"].tags["Terraform"] == "true"
    error_message = "Expected default Terraform tag"
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
    condition     = azurerm_application_gateway.this["test"].tags["Terraform"] == "true"
    error_message = "Default Terraform tag should still be present"
  }

  assert {
    condition     = azurerm_application_gateway.this["test"].tags["environment"] == "dev"
    error_message = "Custom tag should be present"
  }
}
