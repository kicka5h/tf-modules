# az-vpn-gateway

Creates and manages Azure Virtual Network Gateways (VPN) with local network gateways, site-to-site/VNet-to-VNet connections, BGP, and IPsec policy enforcement.

## Usage

```hcl
module "vpn" {
  source              = "../az-vpn-gateway"
  resource_group_name = "rg-networking"
  location            = "eastus2"

  vpn_gateways = {
    main = {
      name = "vpngw-main"
      sku  = "VpnGw2AZ"
      ip_configuration = {
        name                 = "vnetGatewayConfig"
        subnet_id            = module.vnet.subnets["hub-GatewaySubnet"].id
        public_ip_address_id = module.pip.public_ips["vpn"].id
      }
      local_network_gateways = {
        onprem = {
          name            = "lgw-onprem"
          gateway_address = "203.0.113.1"
          address_space   = ["192.168.0.0/16"]
        }
      }
      connections = {
        to_onprem = {
          name                      = "conn-to-onprem"
          type                      = "IPsec"
          local_network_gateway_key = "onprem"
          shared_key                = "SuperSecretKey123"
          ipsec_policy = {
            dh_group         = "DHGroup14"
            ike_encryption   = "AES256"
            ike_integrity    = "SHA256"
            ipsec_encryption = "AES256"
            ipsec_integrity  = "SHA256"
            pfs_group        = "PFS14"
          }
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
| SKU | `vpn_gateways.<key>.sku` | `"Basic"`, `"VpnGw1"`, `"VpnGw2"`, `"VpnGw3"`, `"VpnGw4"`, `"VpnGw5"`, `"VpnGw1AZ"`, `"VpnGw2AZ"`, `"VpnGw3AZ"`, `"VpnGw4AZ"`, `"VpnGw5AZ"` |
| Gateway type | `vpn_gateways.<key>.type` | `"Vpn"` (default), `"ExpressRoute"` |
| VPN type | `vpn_gateways.<key>.vpn_type` | `"RouteBased"` (default), `"PolicyBased"` |
| Generation | `vpn_gateways.<key>.generation` | `"Generation1"`, `"Generation2"` (default), `"None"` |

### Encryption/Security

| What | Variable Path | Valid Values |
| --- | --- | --- |
| DH group | `...connections.<key>.ipsec_policy.dh_group` | `"DHGroup14"`, `"DHGroup24"`, `"ECP256"`, `"ECP384"`, etc. |
| IKE encryption | `...connections.<key>.ipsec_policy.ike_encryption` | `"AES256"`, `"AES192"`, `"AES128"`, `"GCMAES256"`, `"GCMAES128"` (not DES/DES3) |
| IKE integrity | `...connections.<key>.ipsec_policy.ike_integrity` | `"SHA256"`, `"SHA384"`, `"GCMAES256"`, `"GCMAES128"` (not MD5) |
| IPsec encryption | `...connections.<key>.ipsec_policy.ipsec_encryption` | `"AES256"`, `"AES192"`, `"AES128"`, `"GCMAES256"`, `"GCMAES192"`, `"GCMAES128"` (not DES/DES3/None) |
| IPsec integrity | `...connections.<key>.ipsec_policy.ipsec_integrity` | `"SHA256"`, `"GCMAES256"`, `"GCMAES128"` (not MD5) |
| PFS group | `...connections.<key>.ipsec_policy.pfs_group` | `"PFS14"`, `"PFS24"`, `"ECP256"`, `"ECP384"`, `"PFS2048"`, etc. |
| SA lifetime | `...connections.<key>.ipsec_policy.sa_lifetime` | Seconds (default: `27000`) |
| SA data size | `...connections.<key>.ipsec_policy.sa_datasize` | KB (default: `102400000`) |
| Connection protocol | `...connections.<key>.connection_protocol` | `"IKEv2"` (default), `"IKEv1"` |

### Networking

| What | Variable Path | Notes |
| --- | --- | --- |
| IP configuration subnet | `vpn_gateways.<key>.ip_configuration.subnet_id` | Must be `GatewaySubnet` |
| IP configuration PIP | `vpn_gateways.<key>.ip_configuration.public_ip_address_id` | Public IP resource ID |
| Active-active second IP | `vpn_gateways.<key>.second_ip_configuration` | Required for `active_active = true` |
| Active-active | `vpn_gateways.<key>.active_active` | `true`, `false` (default: `false`) |
| BGP enable | `vpn_gateways.<key>.enable_bgp` | `true`, `false` (default: `false`) |
| BGP ASN | `vpn_gateways.<key>.bgp_settings.asn` | ASN number |
| Local GW address | `...local_network_gateways.<key>.gateway_address` | Public IP of remote gateway |
| Local GW FQDN | `...local_network_gateways.<key>.gateway_fqdn` | FQDN of remote gateway |
| Local GW address space | `...local_network_gateways.<key>.address_space` | List of on-prem CIDRs |
| Connection type | `...connections.<key>.type` | `"IPsec"`, `"Vnet2Vnet"`, `"ExpressRoute"` |
| Shared key | `...connections.<key>.shared_key` | Pre-shared key string |
| Routing weight | `...connections.<key>.routing_weight` | Number |

## Enforced Policies

- **Weak encryption blocked**: The module rejects the following algorithms at plan time:
  - `ike_encryption`: `DES`, `DES3` are blocked
  - `ipsec_encryption`: `DES`, `DES3`, `None` are blocked
  - `ike_integrity`: `MD5` is blocked
  - `ipsec_integrity`: `MD5` is blocked
- **Default tags**: `Terraform = "true"` is always applied and merged with caller-provided tags.
