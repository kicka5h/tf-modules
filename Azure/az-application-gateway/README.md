# az-application-gateway

Creates and manages Azure Application Gateways with WAF policies, SSL certificates, URL path maps, health probes, and automatic IP blocklist enforcement for WAF_v2 SKUs.

## Usage

```hcl
module "appgw" {
  source              = "../az-application-gateway"
  resource_group_name = "rg-networking"
  location            = "eastus2"

  application_gateways = {
    web = {
      name = "appgw-web"
      sku = {
        name = "WAF_v2"
        tier = "WAF_v2"
      }
      autoscale_configuration = {
        min_capacity = 1
        max_capacity = 10
      }
      gateway_ip_configuration = {
        name      = "appgw-ipconfig"
        subnet_id = module.vnet.subnets["hub-appgw"].id
      }
      frontend_ip_configurations = {
        public = {
          name                 = "fe-public"
          public_ip_address_id = module.pip.public_ips["appgw"].id
        }
      }
      frontend_ports = {
        https = { name = "port-443", port = 443 }
      }
      backend_address_pools = {
        app = { name = "pool-app", ip_addresses = ["10.0.3.4"] }
      }
      backend_http_settings = {
        app = {
          name     = "https-settings"
          port     = 443
          protocol = "Https"
        }
      }
      http_listeners = {
        https = {
          name                           = "listener-https"
          frontend_ip_configuration_name = "fe-public"
          frontend_port_name             = "port-443"
          protocol                       = "Https"
          ssl_certificate_name           = "wildcard"
        }
      }
      request_routing_rules = {
        main = {
          name                       = "rule-main"
          rule_type                  = "Basic"
          http_listener_name         = "listener-https"
          backend_address_pool_name  = "pool-app"
          backend_http_settings_name = "https-settings"
          priority                   = 100
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

| What | Variable Path | Valid Values |
| --- | --- | --- |
| SKU name | `application_gateways.<key>.sku.name` | `"Standard_v2"`, `"WAF_v2"` |
| SKU tier | `application_gateways.<key>.sku.tier` | `"Standard_v2"`, `"WAF_v2"` |
| Fixed capacity | `application_gateways.<key>.sku.capacity` | Number (omit if using autoscale) |

### Modes

| What | Variable Path | Valid Values | Default |
| --- | --- | --- | --- |
| WAF mode | `application_gateways.<key>.waf_configuration.firewall_mode` | `"Detection"`, `"Prevention"` | `"Prevention"` |
| WAF enabled | `application_gateways.<key>.waf_configuration.enabled` | `true`, `false` | Required for WAF_v2 |
| WAF rule set type | `application_gateways.<key>.waf_configuration.rule_set_type` | `"OWASP"` | `"OWASP"` |
| WAF rule set version | `application_gateways.<key>.waf_configuration.rule_set_version` | `"3.2"`, `"3.1"`, `"3.0"` | `"3.2"` |

### Encryption/Security

| What | Variable Path | Valid Values | Default |
| --- | --- | --- | --- |
| SSL policy type | `application_gateways.<key>.ssl_policy.policy_type` | `"Predefined"`, `"Custom"` | `"Predefined"` |
| SSL policy name | `application_gateways.<key>.ssl_policy.policy_name` | Azure policy name | `"AppGwSslPolicy20220101S"` |
| SSL cert (Key Vault) | `application_gateways.<key>.ssl_certificates.<key>.key_vault_secret_id` | Key Vault secret ID |  |
| SSL cert (inline) | `application_gateways.<key>.ssl_certificates.<key>.data` / `.password` | Base64 PFX + password |  |

### Scaling

| What | Variable Path | Notes |
| --- | --- | --- |
| Autoscale min | `application_gateways.<key>.autoscale_configuration.min_capacity` | Required if autoscaling |
| Autoscale max | `application_gateways.<key>.autoscale_configuration.max_capacity` | Optional upper limit |

### IP/CIDR Updates

The module automatically fetches and enforces IP blocklists on WAF_v2 gateways. **No caller configuration is needed.**

| Source | URL |
| --- | --- |
| Spamhaus DROP | `https://www.spamhaus.org/drop/drop.txt` |
| Spamhaus EDROP | `https://www.spamhaus.org/drop/edrop.txt` |
| Custom org IP blocklist | `https://raw.githubusercontent.com/<org>/blocked-hosts/main/ip-blocklist.txt` |

To update the custom org IP blocklist, commit changes to `github.com/<org>/blocked-hosts/main/ip-blocklist.txt` (one CIDR per line, `#` for comments). Changes take effect on the next `terraform apply`.

## Enforced Policies

- **WAF policy with IP blocklist**: For every `WAF_v2` gateway, a `azurerm_web_application_firewall_policy` is automatically created with a custom rule at priority `1` that blocks all inbound traffic from Spamhaus DROP+EDROP and the org custom IP blocklist (matching on `RemoteAddr`).
- **WAF_v2 requires waf_configuration**: The module rejects WAF_v2 SKU gateways that do not provide `waf_configuration` -- enforced at plan time.
- **Managed OWASP rule set**: The WAF policy includes the managed OWASP rule set using the version from `waf_configuration`.
- **Default tags**: `Terraform = "true"` is always applied and merged with caller-provided tags.
