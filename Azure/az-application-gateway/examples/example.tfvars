resource_group_name = "rg-appgw-prod"
location            = "eastus2"

tags = {
  environment = "production"
  team        = "platform"
}

application_gateways = {
  web = {
    name = "appgw-web-prod"
    sku = {
      name = "WAF_v2"
      tier = "WAF_v2"
    }
    autoscale_configuration = {
      min_capacity = 1
      max_capacity = 10
    }
    gateway_ip_configuration = {
      name      = "gateway-ip-config"
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-hub/subnets/snet-appgw"
    }
    frontend_ip_configurations = {
      public = {
        name                 = "fe-ip-public"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/publicIPAddresses/pip-appgw-web"
      }
    }
    frontend_ports = {
      http = {
        name = "fe-port-80"
        port = 80
      }
      https = {
        name = "fe-port-443"
        port = 443
      }
    }
    backend_address_pools = {
      api = {
        name         = "be-pool-api"
        ip_addresses = ["10.1.0.4", "10.1.0.5"]
      }
      web = {
        name  = "be-pool-web"
        fqdns = ["webapp.azurewebsites.net"]
      }
    }
    backend_http_settings = {
      api = {
        name      = "be-settings-api"
        port      = 443
        protocol  = "Https"
        probe_key = "api_health"
        host_name = "api.example.com"
      }
      web = {
        name                                = "be-settings-web"
        port                                = 443
        protocol                            = "Https"
        probe_key                           = "web_health"
        pick_host_name_from_backend_address = true
      }
    }
    http_listeners = {
      http = {
        name                           = "listener-http"
        frontend_ip_configuration_name = "fe-ip-public"
        frontend_port_name             = "fe-port-80"
        protocol                       = "Http"
      }
      https = {
        name                           = "listener-https"
        frontend_ip_configuration_name = "fe-ip-public"
        frontend_port_name             = "fe-port-443"
        protocol                       = "Https"
        host_names                     = ["api.example.com", "www.example.com"]
        ssl_certificate_name           = "wildcard-example"
      }
    }
    request_routing_rules = {
      http_redirect = {
        name                       = "rule-http"
        rule_type                  = "Basic"
        http_listener_name         = "listener-http"
        backend_address_pool_name  = "be-pool-web"
        backend_http_settings_name = "be-settings-web"
        priority                   = 200
      }
      https_path = {
        name               = "rule-https-path"
        rule_type          = "PathBasedRouting"
        http_listener_name = "listener-https"
        url_path_map_name  = "path-map-main"
        priority           = 100
      }
    }
    probes = {
      api_health = {
        name     = "probe-api"
        protocol = "Https"
        path     = "/healthz"
        host     = "api.example.com"
        interval = 15
        timeout  = 10
      }
      web_health = {
        name                                      = "probe-web"
        protocol                                  = "Https"
        path                                      = "/health"
        pick_host_name_from_backend_http_settings = true
      }
    }
    ssl_certificates = {
      wildcard = {
        name                = "wildcard-example"
        key_vault_secret_id = "https://kv-certs-prod.vault.azure.net/secrets/wildcard-example-com/abc123"
      }
    }
    url_path_maps = {
      main = {
        name                               = "path-map-main"
        default_backend_address_pool_name  = "be-pool-web"
        default_backend_http_settings_name = "be-settings-web"
        path_rules = {
          api = {
            name                       = "path-rule-api"
            paths                      = ["/api/*"]
            backend_address_pool_name  = "be-pool-api"
            backend_http_settings_name = "be-settings-api"
          }
        }
      }
    }
    waf_configuration = {
      enabled          = true
      firewall_mode    = "Prevention"
      rule_set_type    = "OWASP"
      rule_set_version = "3.2"
    }
    ssl_policy = {
      policy_type = "Predefined"
      policy_name = "AppGwSslPolicy20220101S"
    }
  }
}
