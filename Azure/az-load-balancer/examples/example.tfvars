resource_group_name = "rg-network"
location            = "eastus2"

load_balancers = {
  public_web = {
    name = "lb-public-web"
    sku  = "Standard"
    frontend_ip_configurations = {
      primary = {
        name                 = "fe-public"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/publicIPAddresses/pip-lb-web"
        zones                = ["1", "2", "3"]
      }
    }
    backend_pools = {
      web_servers = {
        name = "bp-web-servers"
      }
    }
    probes = {
      http_health = {
        name         = "probe-http"
        protocol     = "Http"
        port         = 80
        request_path = "/health"
      }
      https_health = {
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
        frontend_ip_configuration_name = "fe-public"
        backend_address_pool_key       = "web_servers"
        probe_key                      = "http_health"
      }
      https = {
        name                           = "rule-https"
        protocol                       = "Tcp"
        frontend_port                  = 443
        backend_port                   = 443
        frontend_ip_configuration_name = "fe-public"
        backend_address_pool_key       = "web_servers"
        probe_key                      = "https_health"
        disable_outbound_snat          = true
      }
    }
    outbound_rules = {
      default = {
        name                           = "outbound-default"
        protocol                       = "All"
        frontend_ip_configuration_name = "fe-public"
        backend_address_pool_key       = "web_servers"
        allocated_outbound_ports       = 1024
      }
    }
  }

  internal_sql = {
    name = "lb-internal-sql"
    sku  = "Standard"
    frontend_ip_configurations = {
      primary = {
        name                          = "fe-sql"
        subnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-data/subnets/snet-sql"
        private_ip_address            = "10.1.2.10"
        private_ip_address_allocation = "Static"
        zones                         = ["1", "2", "3"]
      }
    }
    backend_pools = {
      sql_servers = {
        name = "bp-sql-servers"
      }
    }
    probes = {
      sql_health = {
        name     = "probe-sql"
        protocol = "Tcp"
        port     = 1433
      }
    }
    rules = {
      sql = {
        name                           = "rule-sql"
        protocol                       = "Tcp"
        frontend_port                  = 1433
        backend_port                   = 1433
        frontend_ip_configuration_name = "fe-sql"
        backend_address_pool_key       = "sql_servers"
        probe_key                      = "sql_health"
        enable_floating_ip             = true
      }
    }
  }
}

tags = {
  environment = "production"
  managed_by  = "terraform"
}
