# az-naming

Generates standardized Azure resource names following a configurable convention. Takes environment, region, and workload as inputs and outputs names that enforce an org-wide naming standard.

## Naming Convention

All resource names follow the pattern:

```
{prefix}-{workload}-{environment}-{region_short}[-{suffix}]
```

| Component | Source | Example |
| --- | --- | --- |
| `prefix` | Azure resource type abbreviation (e.g., `rg`, `vnet`, `st`) | `rg` |
| `workload` | `var.workload` | `app` |
| `environment` | `var.environment` | `dev` |
| `region_short` | Looked up from `var.region_abbreviations` | `eus` |
| `suffix` | `var.suffix` (optional) | `001` |

**Example:** `rg-app-dev-eus`, `vnet-app-dev-eus`, `stappdeveus`

## Resource Type Prefixes

| Output | Prefix | Separator | Max Length | Example |
| --- | --- | --- | --- | --- |
| `resource_group` | `rg` | `-` | — | `rg-app-dev-eus` |
| `virtual_network` | `vnet` | `-` | — | `vnet-app-dev-eus` |
| `subnet` | `snet` | `-` | — | `snet-app-dev-eus` |
| `network_security_group` | `nsg` | `-` | — | `nsg-app-dev-eus` |
| `route_table` | `rt` | `-` | — | `rt-app-dev-eus` |
| `public_ip` | `pip` | `-` | — | `pip-app-dev-eus` |
| `nat_gateway` | `ng` | `-` | — | `ng-app-dev-eus` |
| `firewall` | `fw` | `-` | — | `fw-app-dev-eus` |
| `firewall_policy` | `fwp` | `-` | — | `fwp-app-dev-eus` |
| `application_gateway` | `agw` | `-` | — | `agw-app-dev-eus` |
| `load_balancer` | `lb` | `-` | — | `lb-app-dev-eus` |
| `private_endpoint` | `pe` | `-` | — | `pe-app-dev-eus` |
| `front_door` | `fd` | `-` | — | `fd-app-dev-eus` |
| `vpn_gateway` | `vpng` | `-` | — | `vpng-app-dev-eus` |
| `express_route` | `erc` | `-` | — | `erc-app-dev-eus` |
| `virtual_machine` | `vm` | `-` | — | `vm-app-dev-eus` |
| `vmss` | `vmss` | `-` | — | `vmss-app-dev-eus` |
| `aks_cluster` | `aks` | `-` | — | `aks-app-dev-eus` |
| `container_instance` | `ci` | `-` | — | `ci-app-dev-eus` |
| `container_registry` | `cr` | none | 50 | `crappdeveus` |
| `storage_account` | `st` | none | 24 | `stappdeveus` |
| `key_vault` | `kv` | `-` | 24 | `kv-app-dev-eus` |
| `app_service_plan` | `asp` | `-` | — | `asp-app-dev-eus` |
| `app_service` | `app` | `-` | — | `app-app-dev-eus` |
| `dns_zone` | none | `-` | — | `app-dev-eus` |
| `log_analytics` | `log` | `-` | — | `log-app-dev-eus` |

## Usage

### Basic

```hcl
module "naming" {
  source = "../az-naming"

  environment = "dev"
  region      = "eastus"
  workload    = "app"
}

resource "azurerm_resource_group" "main" {
  name     = module.naming.resource_group   # rg-app-dev-eus
  location = "eastus"
}
```

### With suffix

```hcl
module "naming" {
  source = "../az-naming"

  environment = "prod"
  region      = "westeurope"
  workload    = "data"
  suffix      = "001"
}

# Produces: rg-data-prod-weu-001, vnet-data-prod-weu-001, etc.
```

### With az-virtual-network

```hcl
module "naming" {
  source = "../az-naming"

  environment = "dev"
  region      = "eastus"
  workload    = "app"
}

module "vnet" {
  source = "../az-virtual-network"

  resource_group_name = module.naming.resource_group
  location            = "eastus"

  vnets = {
    hub = {
      name          = module.naming.virtual_network
      address_space = ["10.0.0.0/16"]
      subnets = {
        default = {
          name             = "${module.naming.subnet}-default"
          address_prefixes = ["10.0.1.0/24"]
        }
      }
    }
  }
}
```

### Using the names map

```hcl
# Access any name through the map
output "all" {
  value = module.naming.names
}

# Or build a custom name from the base
output "custom_name" {
  value = "myprefix-${module.naming.base_name}"
}
```

### Customizing region abbreviations

```hcl
module "naming" {
  source = "../az-naming"

  environment = "dev"
  region      = "brazilsouth"
  workload    = "app"

  # Add or override region abbreviations
  region_abbreviations = merge(
    module.naming.defaults_not_available,  # start from scratch or use your own map
    {
      "brazilsouth"    = "brs"
      "southafricanorth" = "san"
    }
  )
}
```

Or pass a complete custom map to replace the defaults entirely.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `environment` | `string` | yes | — | `dev`, `qa`, `stage`, or `prod` |
| `region` | `string` | yes | — | Azure region name (e.g., `eastus`) |
| `workload` | `string` | yes | — | Short workload/project name, lowercase alphanumeric |
| `separator` | `string` | no | `-` | Separator between name components |
| `suffix` | `string` | no | `""` | Optional additional suffix |
| `region_abbreviations` | `map(string)` | no | (see variables.tf) | Map of region names to abbreviations |

## Outputs

| Output | Description |
| --- | --- |
| `base_name` | Base name without prefix (e.g., `app-dev-eus`) |
| `base_name_nosep` | Base name with no separators (e.g., `appdeveus`) |
| `names` | Map of all resource types to their generated names |
| `resource_group` | `rg-{base_name}` |
| `virtual_network` | `vnet-{base_name}` |
| `subnet` | `snet-{base_name}` |
| `storage_account` | `st{base_name_nosep}` (max 24 chars) |
| `container_registry` | `cr{base_name_nosep}` (max 50 chars) |
| `key_vault` | `kv-{base_name}` (max 24 chars) |
| ... | See outputs.tf for the full list |

## Testing

```bash
cd az-naming
terraform init
terraform test
```
