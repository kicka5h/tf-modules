resource_group_name = "rg-frontdoor-prod"

front_doors = {
  main = {
    name     = "fd-contoso-prod"
    sku_name = "Premium_AzureFrontDoor"

    endpoints = {
      web = {
        name = "fd-contoso-web"
      }
      api = {
        name = "fd-contoso-api"
      }
    }

    origin_groups = {
      webapp = {
        name = "og-webapp"
        load_balancing = {
          sample_size                        = 4
          successful_samples_required        = 3
          additional_latency_in_milliseconds = 50
        }
        health_probe = {
          path                = "/health"
          protocol            = "Https"
          interval_in_seconds = 60
          request_type        = "GET"
        }
        origins = {
          primary = {
            name               = "webapp-primary"
            host_name          = "app-contoso-prod-eastus.azurewebsites.net"
            origin_host_header = "app-contoso-prod-eastus.azurewebsites.net"
            priority           = 1
            weight             = 1000
          }
          secondary = {
            name               = "webapp-secondary"
            host_name          = "app-contoso-prod-westus.azurewebsites.net"
            origin_host_header = "app-contoso-prod-westus.azurewebsites.net"
            priority           = 2
            weight             = 1000
          }
        }
      }
      api = {
        name = "og-api"
        load_balancing = {
          sample_size                        = 4
          successful_samples_required        = 2
          additional_latency_in_milliseconds = 100
        }
        health_probe = {
          path                = "/api/health"
          protocol            = "Https"
          interval_in_seconds = 30
          request_type        = "GET"
        }
        origins = {
          primary = {
            name               = "api-primary"
            host_name          = "api-contoso-prod-eastus.azurewebsites.net"
            origin_host_header = "api-contoso-prod-eastus.azurewebsites.net"
            priority           = 1
            weight             = 1000
          }
          secondary = {
            name               = "api-secondary"
            host_name          = "api-contoso-prod-westus.azurewebsites.net"
            origin_host_header = "api-contoso-prod-westus.azurewebsites.net"
            priority           = 2
            weight             = 1000
          }
        }
      }
    }

    # Custom WAF rules (priority >= 100, 1-99 reserved for module-enforced blocklists)
    custom_waf_rules = {
      rate_limit_api = {
        name     = "RateLimitAPI"
        priority = 100
        type     = "RateLimitRule"
        action   = "Block"
        match_conditions = [
          {
            match_variable = "RequestUri"
            operator       = "Contains"
            match_values   = ["/api/"]
          }
        ]
      }
      geo_block = {
        name     = "GeoBlock"
        priority = 200
        action   = "Block"
        match_conditions = [
          {
            match_variable = "SocketAddr"
            operator       = "GeoMatch"
            match_values   = ["CN", "RU"]
          }
        ]
      }
    }

    routes = {
      web_default = {
        name                   = "route-web"
        endpoint_key           = "web"
        origin_group_key       = "webapp"
        patterns_to_match      = ["/*"]
        supported_protocols    = ["Http", "Https"]
        forwarding_protocol    = "HttpsOnly"
        https_redirect_enabled = true
        link_to_default_domain = true
      }
      api_default = {
        name                   = "route-api"
        endpoint_key           = "api"
        origin_group_key       = "api"
        patterns_to_match      = ["/api/*"]
        supported_protocols    = ["Https"]
        forwarding_protocol    = "HttpsOnly"
        https_redirect_enabled = true
        link_to_default_domain = true
      }
    }
  }
}

tags = {
  environment = "production"
  team        = "platform"
}
