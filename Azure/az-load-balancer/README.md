# az-load-balancer

Creates and manages Azure Load Balancers with frontend IPs, backend pools, health probes, load balancing rules, NAT rules, and outbound rules.

## Usage

```hcl
module "lb" {
  source              = "../az-load-balancer"
  resource_group_name = "rg-networking"
  location            = "eastus2"

  load_balancers = {
    web = {
      name = "lb-web"
      frontend_ip_configurations = {
        public = {
          name                 = "fe-public"
          public_ip_address_id = module.pip.public_ips["lb"].id
        }
      }
      backend_pools = {
        app = { name = "pool-app" }
      }
      probes = {
        http = {
          name         = "probe-http"
          protocol     = "Http"
          port         = 80
          request_path = "/"
        }
      }
      rules = {
        http = {
          name                           = "rule-http"
          protocol                       = "Tcp"
          frontend_port                  = 80
          backend_port                   = 80
          frontend_ip_configuration_name = "fe-public"
          backend_address_pool_key       = "app"
          probe_key                      = "http"
        }
      }
    }
  }

  tags = {
    Environment = "production"
  }
}
```

## Configuration Reference

### Tags

| What | Variable | Notes |
| --- | --- | --- |
| Custom tags | `tags` | `map(string)`, merged with default tags |

### SKU/Tier

| What | Variable Path | Valid Values | Default |
| --- | --- | --- | --- |
| SKU | `load_balancers.<key>.sku` | `"Basic"`, `"Standard"`, `"Gateway"` | `"Standard"` |
| SKU tier | `load_balancers.<key>.sku_tier` | `"Regional"`, `"Global"` | `"Regional"` |

### Networking

| What | Variable Path | Notes |
| --- | --- | --- |
| Public frontend | `load_balancers.<key>.frontend_ip_configurations.<name>.public_ip_address_id` | PIP resource ID |
| Private frontend | `load_balancers.<key>.frontend_ip_configurations.<name>.subnet_id` | Subnet resource ID |
| Private IP | `load_balancers.<key>.frontend_ip_configurations.<name>.private_ip_address` | Static IP (optional) |
| Private IP allocation | `load_balancers.<key>.frontend_ip_configurations.<name>.private_ip_address_allocation` | `"Dynamic"` (default), `"Static"` |
| Frontend zones | `load_balancers.<key>.frontend_ip_configurations.<name>.zones` | `["1","2","3"]`, etc. |

### Health Probes

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Protocol | `load_balancers.<key>.probes.<name>.protocol` | `"Http"`, `"Https"`, `"Tcp"` |
| Port | `load_balancers.<key>.probes.<name>.port` | Port number |
| Request path | `load_balancers.<key>.probes.<name>.request_path` | URL path (required for Http/Https) |
| Interval | `load_balancers.<key>.probes.<name>.interval_in_seconds` | Default: `5` |
| Unhealthy threshold | `load_balancers.<key>.probes.<name>.number_of_probes` | Default: `2` |

### Load Balancing Rules

| What | Variable Path | Notes |
| --- | --- | --- |
| Protocol | `load_balancers.<key>.rules.<name>.protocol` | `"Tcp"`, `"Udp"`, `"All"` |
| Frontend port | `load_balancers.<key>.rules.<name>.frontend_port` | Port number |
| Backend port | `load_balancers.<key>.rules.<name>.backend_port` | Port number |
| Backend pool ref | `load_balancers.<key>.rules.<name>.backend_address_pool_key` | Key from `backend_pools` map |
| Probe ref | `load_balancers.<key>.rules.<name>.probe_key` | Key from `probes` map |
| Floating IP | `load_balancers.<key>.rules.<name>.enable_floating_ip` | `true`, `false` (default: `false`) |
| Load distribution | `load_balancers.<key>.rules.<name>.load_distribution` | `"Default"`, `"SourceIP"`, `"SourceIPProtocol"` |
| Disable outbound SNAT | `load_balancers.<key>.rules.<name>.disable_outbound_snat` | `true`, `false` (default: `false`) |

### NAT Rules

| What | Variable Path | Notes |
| --- | --- | --- |
| Protocol | `load_balancers.<key>.nat_rules.<name>.protocol` | `"Tcp"`, `"Udp"`, `"All"` |
| Frontend/backend port | `load_balancers.<key>.nat_rules.<name>.frontend_port` / `.backend_port` | Port numbers |

### Outbound Rules

| What | Variable Path | Notes |
| --- | --- | --- |
| Protocol | `load_balancers.<key>.outbound_rules.<name>.protocol` | `"Tcp"`, `"Udp"`, `"All"` |
| Allocated outbound ports | `load_balancers.<key>.outbound_rules.<name>.allocated_outbound_ports` | Number or `null` |
| Backend pool ref | `load_balancers.<key>.outbound_rules.<name>.backend_address_pool_key` | Key from `backend_pools` map |

## Enforced Policies

- **Default tags**: `Terraform = "true"` is always applied and merged with caller-provided tags.
- **SKU validation**: Only `"Basic"`, `"Standard"`, or `"Gateway"` are accepted -- enforced at plan time.
