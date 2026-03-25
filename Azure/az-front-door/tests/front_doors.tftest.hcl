mock_provider "azurerm" {}
mock_provider "http" {}

variables {
  resource_group_name = "rg-test"

  front_doors = {
    web = {
      name     = "fd-web"
      sku_name = "Standard_AzureFrontDoor"
      endpoints = {
        main = {
          name = "fd-web-main"
        }
      }
      origin_groups = {
        app = {
          name = "og-app"
          health_probe = {
            path     = "/health"
            protocol = "Https"
          }
          origins = {
            primary = {
              name      = "origin-primary"
              host_name = "app-primary.azurewebsites.net"
              priority  = 1
              weight    = 1000
            }
            secondary = {
              name      = "origin-secondary"
              host_name = "app-secondary.azurewebsites.net"
              priority  = 2
              weight    = 1000
            }
          }
        }
      }
      routes = {
        default = {
          name             = "route-default"
          endpoint_key     = "main"
          origin_group_key = "app"
        }
      }
    }
  }
}

run "creates_front_door_profile" {
  command = plan

  assert {
    condition     = length(azurerm_cdn_frontdoor_profile.this) == 1
    error_message = "Expected 1 Front Door profile"
  }

  assert {
    condition     = azurerm_cdn_frontdoor_profile.this["web"].name == "fd-web"
    error_message = "Expected profile name to be fd-web"
  }

  assert {
    condition     = azurerm_cdn_frontdoor_profile.this["web"].sku_name == "Standard_AzureFrontDoor"
    error_message = "Expected SKU to be Standard_AzureFrontDoor"
  }
}

run "creates_endpoint" {
  command = plan

  assert {
    condition     = length(azurerm_cdn_frontdoor_endpoint.this) == 1
    error_message = "Expected 1 endpoint"
  }

  assert {
    condition     = azurerm_cdn_frontdoor_endpoint.this["web-main"].name == "fd-web-main"
    error_message = "Expected endpoint name to be fd-web-main"
  }
}

run "creates_origin_group" {
  command = plan

  assert {
    condition     = length(azurerm_cdn_frontdoor_origin_group.this) == 1
    error_message = "Expected 1 origin group"
  }

  assert {
    condition     = azurerm_cdn_frontdoor_origin_group.this["web-app"].name == "og-app"
    error_message = "Expected origin group name to be og-app"
  }
}

run "creates_origins" {
  command = plan

  assert {
    condition     = length(azurerm_cdn_frontdoor_origin.this) == 2
    error_message = "Expected 2 origins"
  }

  assert {
    condition     = azurerm_cdn_frontdoor_origin.this["web-app-primary"].name == "origin-primary"
    error_message = "Expected origin name to be origin-primary"
  }

  assert {
    condition     = azurerm_cdn_frontdoor_origin.this["web-app-primary"].host_name == "app-primary.azurewebsites.net"
    error_message = "Expected origin host_name to be app-primary.azurewebsites.net"
  }

  assert {
    condition     = azurerm_cdn_frontdoor_origin.this["web-app-secondary"].name == "origin-secondary"
    error_message = "Expected origin name to be origin-secondary"
  }
}

run "creates_route" {
  command = plan

  assert {
    condition     = length(azurerm_cdn_frontdoor_route.this) == 1
    error_message = "Expected 1 route"
  }

  assert {
    condition     = azurerm_cdn_frontdoor_route.this["web-default"].name == "route-default"
    error_message = "Expected route name to be route-default"
  }

  assert {
    condition     = azurerm_cdn_frontdoor_route.this["web-default"].https_redirect_enabled == true
    error_message = "Expected HTTPS redirect to be enabled by default"
  }
}

run "no_waf_policy_for_standard_sku" {
  command = plan

  assert {
    condition     = length(azurerm_cdn_frontdoor_firewall_policy.this) == 0
    error_message = "Expected no WAF policy for Standard SKU profile"
  }

  assert {
    condition     = length(azurerm_cdn_frontdoor_security_policy.this) == 0
    error_message = "Expected no security policy for Standard SKU profile"
  }
}
