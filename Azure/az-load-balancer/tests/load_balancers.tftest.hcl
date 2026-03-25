mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  load_balancers = {
    public = {
      name = "lb-public"
      sku  = "Standard"
      frontend_ip_configurations = {
        primary = {
          name                 = "fe-primary"
          public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/pip-lb"
        }
      }
      backend_pools = {
        web = {
          name = "bp-web"
        }
      }
      probes = {
        http = {
          name         = "probe-http"
          protocol     = "Http"
          port         = 80
          request_path = "/health"
        }
        https = {
          name         = "probe-https"
          protocol     = "Https"
          port         = 443
          request_path = "/health"
        }
      }
      rules = {
        http = {
          name                           = "rule-http"
          protocol                       = "Tcp"
          frontend_port                  = 80
          backend_port                   = 80
          frontend_ip_configuration_name = "fe-primary"
          backend_address_pool_key       = "web"
          probe_key                      = "http"
        }
        https = {
          name                           = "rule-https"
          protocol                       = "Tcp"
          frontend_port                  = 443
          backend_port                   = 443
          frontend_ip_configuration_name = "fe-primary"
          backend_address_pool_key       = "web"
          probe_key                      = "https"
        }
      }
    }
    internal = {
      name = "lb-internal"
      sku  = "Standard"
      frontend_ip_configurations = {
        primary = {
          name                          = "fe-internal"
          subnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/lb-subnet"
          private_ip_address            = "10.0.1.10"
          private_ip_address_allocation = "Static"
        }
      }
      backend_pools = {
        app = {
          name = "bp-app"
        }
      }
      probes = {
        tcp = {
          name     = "probe-tcp"
          protocol = "Tcp"
          port     = 8080
        }
      }
      rules = {
        app = {
          name                           = "rule-app"
          protocol                       = "Tcp"
          frontend_port                  = 8080
          backend_port                   = 8080
          frontend_ip_configuration_name = "fe-internal"
          backend_address_pool_key       = "app"
          probe_key                      = "tcp"
        }
      }
    }
  }
}

run "creates_multiple_load_balancers" {
  command = plan

  assert {
    condition     = length(azurerm_lb.this) == 2
    error_message = "Expected 2 load balancers"
  }

  assert {
    condition     = azurerm_lb.this["public"].name == "lb-public"
    error_message = "Expected public LB name to be lb-public"
  }

  assert {
    condition     = azurerm_lb.this["internal"].name == "lb-internal"
    error_message = "Expected internal LB name to be lb-internal"
  }
}

run "creates_backend_pools" {
  command = plan

  assert {
    condition     = length(azurerm_lb_backend_address_pool.this) == 2
    error_message = "Expected 2 backend pools"
  }

  assert {
    condition     = azurerm_lb_backend_address_pool.this["public-web"].name == "bp-web"
    error_message = "Expected public-web backend pool name to be bp-web"
  }

  assert {
    condition     = azurerm_lb_backend_address_pool.this["internal-app"].name == "bp-app"
    error_message = "Expected internal-app backend pool name to be bp-app"
  }
}

run "creates_probes" {
  command = plan

  assert {
    condition     = length(azurerm_lb_probe.this) == 3
    error_message = "Expected 3 probes across both load balancers"
  }

  assert {
    condition     = azurerm_lb_probe.this["public-http"].name == "probe-http"
    error_message = "Expected public-http probe name"
  }

  assert {
    condition     = azurerm_lb_probe.this["public-http"].protocol == "Http"
    error_message = "Expected public-http probe protocol to be Http"
  }

  assert {
    condition     = azurerm_lb_probe.this["public-http"].port == 80
    error_message = "Expected public-http probe port to be 80"
  }

  assert {
    condition     = azurerm_lb_probe.this["internal-tcp"].protocol == "Tcp"
    error_message = "Expected internal-tcp probe protocol to be Tcp"
  }
}

run "creates_rules" {
  command = plan

  assert {
    condition     = length(azurerm_lb_rule.this) == 3
    error_message = "Expected 3 rules across both load balancers"
  }

  assert {
    condition     = azurerm_lb_rule.this["public-http"].name == "rule-http"
    error_message = "Expected public-http rule name"
  }

  assert {
    condition     = azurerm_lb_rule.this["public-http"].frontend_port == 80
    error_message = "Expected public-http rule frontend port to be 80"
  }

  assert {
    condition     = azurerm_lb_rule.this["public-http"].backend_port == 80
    error_message = "Expected public-http rule backend port to be 80"
  }

  assert {
    condition     = azurerm_lb_rule.this["public-https"].frontend_port == 443
    error_message = "Expected public-https rule frontend port to be 443"
  }
}

run "sets_location_and_resource_group" {
  command = plan

  assert {
    condition     = azurerm_lb.this["public"].location == "eastus2"
    error_message = "Expected location to be eastus2"
  }

  assert {
    condition     = azurerm_lb.this["public"].resource_group_name == "rg-test"
    error_message = "Expected resource group to be rg-test"
  }
}

run "sets_sku" {
  command = plan

  assert {
    condition     = azurerm_lb.this["public"].sku == "Standard"
    error_message = "Expected SKU to be Standard"
  }

  assert {
    condition     = azurerm_lb.this["public"].sku_tier == "Regional"
    error_message = "Expected SKU tier to be Regional"
  }
}
