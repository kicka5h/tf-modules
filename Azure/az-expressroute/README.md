# az-expressroute

Creates and manages Azure ExpressRoute circuits with private, public, and Microsoft peerings.

## Usage

```hcl
module "expressroute" {
  source              = "../az-expressroute"
  resource_group_name = "rg-networking"
  location            = "eastus2"

  expressroute_circuits = {
    primary = {
      name                  = "er-primary"
      service_provider_name = "Equinix"
      peering_location      = "Washington DC"
      bandwidth_in_mbps     = 1000
      sku = {
        tier   = "Premium"
        family = "UnlimitedData"
      }
      peerings = {
        private = {
          peering_type                  = "AzurePrivatePeering"
          vlan_id                       = 100
          primary_peer_address_prefix   = "10.0.0.0/30"
          secondary_peer_address_prefix = "10.0.0.4/30"
          peer_asn                      = 65001
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
| SKU tier | `expressroute_circuits.<key>.sku.tier` | `"Standard"`, `"Premium"` |
| SKU family | `expressroute_circuits.<key>.sku.family` | `"MeteredData"`, `"UnlimitedData"` |

### Networking

| What | Variable Path | Notes |
| --- | --- | --- |
| Service provider | `expressroute_circuits.<key>.service_provider_name` | e.g. `"Equinix"`, `"AT&T"` |
| Peering location | `expressroute_circuits.<key>.peering_location` | e.g. `"Washington DC"`, `"Silicon Valley"` |
| Bandwidth | `expressroute_circuits.<key>.bandwidth_in_mbps` | Bandwidth in Mbps |
| Classic operations | `expressroute_circuits.<key>.allow_classic_operations` | `true`, `false` (default: `false`) |
| Peering type | `...peerings.<key>.peering_type` | `"AzurePrivatePeering"`, `"AzurePublicPeering"`, `"MicrosoftPeering"` |
| VLAN ID | `...peerings.<key>.vlan_id` | VLAN tag number |
| Primary prefix | `...peerings.<key>.primary_peer_address_prefix` | /30 CIDR |
| Secondary prefix | `...peerings.<key>.secondary_peer_address_prefix` | /30 CIDR |
| Peer ASN | `...peerings.<key>.peer_asn` | Remote ASN number |
| Shared key | `...peerings.<key>.shared_key` | Optional pre-shared key (sensitive) |
| Microsoft peering prefixes | `...peerings.<key>.microsoft_peering_config.advertised_public_prefixes` | List of public CIDRs (required for MicrosoftPeering) |

## Enforced Policies

- **MicrosoftPeering requires config**: The module rejects `MicrosoftPeering` type peerings that omit `microsoft_peering_config` -- enforced at plan time.
- **Default tags**: `Terraform = "true"` is always applied and merged with caller-provided tags.
