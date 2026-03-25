# az-front-door

Creates and manages Azure Front Door profiles with endpoints, origin groups, origins, routes, and automatic WAF policy enforcement with IP/FQDN blocklists for Premium SKUs.

## Usage

```hcl
module "frontdoor" {
  source              = "../az-front-door"
  resource_group_name = "rg-networking"

  front_doors = {
    main = {
      name     = "fd-main"
      sku_name = "Premium_AzureFrontDoor"
      endpoints = {
        web = { name = "fd-web-endpoint" }
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
              host_name = "app.example.com"
            }
          }
        }
      }
      routes = {
        default = {
          name             = "route-default"
          endpoint_key     = "web"
          origin_group_key = "app"
        }
      }
      custom_waf_rules = {
        geo_block = {
          name     = "GeoBlock"
          priority = 100
          action   = "Block"
          match_conditions = [{
            match_variable = "RemoteAddr"
            operator       = "GeoMatch"
            match_values   = ["CN", "RU"]
          }]
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

| What | Variable Path | Valid Values |
| --- | --- | --- |
| SKU | `front_doors.<key>.sku_name` | `"Standard_AzureFrontDoor"`, `"Premium_AzureFrontDoor"` |

WAF policies (and therefore blocklist enforcement) are only created for `Premium_AzureFrontDoor` profiles.

### Custom Rules

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Rule name | `front_doors.<key>.custom_waf_rules.<key>.name` | String |
| Rule priority | `front_doors.<key>.custom_waf_rules.<key>.priority` | `100`+ (1-99 reserved) |
| Rule type | `front_doors.<key>.custom_waf_rules.<key>.type` | `"MatchRule"` (default), `"RateLimitRule"` |
| Action | `front_doors.<key>.custom_waf_rules.<key>.action` | `"Allow"`, `"Block"`, `"Log"`, `"Redirect"` |
| Match variable | `...match_conditions[].match_variable` | `"RemoteAddr"`, `"RequestHeader"`, `"QueryString"`, etc. |
| Operator | `...match_conditions[].operator` | `"IPMatch"`, `"GeoMatch"`, `"Contains"`, `"Equal"`, etc. |

### Networking

| What | Variable Path | Notes |
| --- | --- | --- |
| Endpoint enabled | `front_doors.<key>.endpoints.<key>.enabled` | `true` (default), `false` |
| Origin host name | `front_doors.<key>.origin_groups.<key>.origins.<key>.host_name` | FQDN of the origin |
| Origin ports | `...origins.<key>.http_port` / `.https_port` | Default: `80` / `443` |
| Origin host header | `...origins.<key>.origin_host_header` | Override host header |
| Cert name check | `...origins.<key>.certificate_name_check_enabled` | `true` (default), `false` |
| Route patterns | `front_doors.<key>.routes.<key>.patterns_to_match` | Default: `["/*"]` |
| Forwarding protocol | `front_doors.<key>.routes.<key>.forwarding_protocol` | `"HttpsOnly"` (default), `"HttpOnly"`, `"MatchRequest"` |
| HTTPS redirect | `front_doors.<key>.routes.<key>.https_redirect_enabled` | `true` (default), `false` |

### Scaling

| What | Variable Path | Notes |
| --- | --- | --- |
| Origin priority | `...origins.<key>.priority` | `1`--`5` (default: `1`) |
| Origin weight | `...origins.<key>.weight` | `1`--`1000` (default: `1000`) |
| Load balancing sample size | `...origin_groups.<key>.load_balancing.sample_size` | Default: `4` |
| Successful samples required | `...origin_groups.<key>.load_balancing.successful_samples_required` | Default: `3` |
| Additional latency | `...origin_groups.<key>.load_balancing.additional_latency_in_milliseconds` | Default: `50` |

### IP/CIDR Updates

The module automatically fetches and enforces IP blocklists on Premium profiles. **No caller configuration is needed.**

| Source | URL |
| --- | --- |
| Spamhaus DROP | `https://www.spamhaus.org/drop/drop.txt` |
| Spamhaus EDROP | `https://www.spamhaus.org/drop/edrop.txt` |
| Custom org IP blocklist | `https://raw.githubusercontent.com/<org>/blocked-hosts/main/ip-blocklist.txt` |

To update the custom org IP blocklist, commit changes to `github.com/<org>/blocked-hosts/main/ip-blocklist.txt` (one CIDR per line, `#` for comments). Changes take effect on the next `terraform apply`.

### FQDN Updates

The module automatically fetches and enforces FQDN blocklists on Premium profiles. **No caller configuration is needed.**

| Source | URL |
| --- | --- |
| Ultimate Hosts Blacklist | `https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/master/hosts/hosts0` |
| Custom org FQDN blocklist | `https://raw.githubusercontent.com/<org>/blocked-hosts/main/fqdn-blocklist.txt` |

To update the custom org FQDN blocklist, commit changes to `github.com/<org>/blocked-hosts/main/fqdn-blocklist.txt` (one domain per line, `#` for comments). Changes take effect on the next `terraform apply`.

| What | Variable | Notes |
| --- | --- | --- |
| Max FQDNs imported | `fqdn_blocklist_max` | Default: `1000`. Set to `0` to disable Ultimate Hosts import. |

## Reserved Priority Ranges

| Range | Owner | Purpose |
| --- | --- | --- |
| `1` | Module | IP blocklist deny rule (`BlocklistDenyByIP`) |
| `2` | Module | FQDN blocklist deny rule (`BlocklistDenyByFQDN`) |
| `1`--`99` | Module | Reserved -- do not use for caller custom WAF rules |
| `100`+ | Caller | Available for user-defined custom WAF rules |

Caller custom WAF rule priorities **must** be `>= 100`.

## Enforced Policies

- **WAF policy on Premium profiles**: For every `Premium_AzureFrontDoor` profile, a `azurerm_cdn_frontdoor_firewall_policy` is automatically created in `Prevention` mode with:
  - Custom rule at priority `1`: Blocks inbound traffic from Spamhaus DROP+EDROP and org IP blocklist (matching on `RemoteAddr`)
  - Custom rule at priority `2`: Blocks requests with `Host` header matching blocklisted FQDNs
  - Managed rule set: `DefaultRuleSet` v1.0 (action: Block)
  - Managed rule set: `Microsoft_BotManagerRuleSet` v1.0 (action: Block)
- **Security policy association**: The WAF policy is automatically associated with all endpoints in each Premium profile via a security policy matching `/*`.
- **Default tags**: `Terraform = "true"` is always applied and merged with caller-provided tags.
