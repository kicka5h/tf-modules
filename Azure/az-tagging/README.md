# az-tagging

Enforces a required tag schema and outputs a merged tag map that every other module consumes. Validates that required tags are present and rejects plans with missing or invalid tags.

## The Problem

- Resources get deployed without tags, making cost attribution impossible
- Teams use inconsistent tag keys (`env` vs `environment` vs `Environment`)
- No enforcement of required metadata like owner or cost center
- Data classification is missing or freeform text

## How It Works

1. **Define** required tags through validated input variables
2. **Validate** at plan time — Terraform rejects invalid environments, empty owners, etc.
3. **Merge** additional custom tags without allowing overrides of required tags
4. **Output** a single tag map that feeds into every other module

## Required Tags

| Tag | Variable | Required | Default | Allowed Values |
| --- | --- | --- | --- | --- |
| `Terraform` | (automatic) | Yes | `"true"` | — |
| `environment` | `environment` | Yes | — | `dev`, `qa`, `stage`, `prod` |
| `owner` | `owner` | Yes | — | Any non-empty string |
| `cost_center` | `cost_center` | Yes | — | Any non-empty string |
| `data_classification` | `data_classification` | No | `"internal"` | `public`, `internal`, `confidential`, `restricted` |
| `project` | `project` | Yes | — | Any non-empty string |
| `managed_by` | `managed_by` | No | `"terraform"` | Any string |

## Data Classification Levels

| Level | Description |
| --- | --- |
| `public` | Information freely available to anyone |
| `internal` | General internal information, not sensitive |
| `confidential` | Sensitive business data, limited access |
| `restricted` | Highly sensitive data (PII, financial, regulated) |

## Usage

### Basic

```hcl
module "tags" {
  source = "../az-tagging"

  environment = "prod"
  owner       = "sre-team"
  cost_center = "CC-5678"
  project     = "api-gateway"
}
```

### With additional tags

```hcl
module "tags" {
  source = "../az-tagging"

  environment         = "prod"
  owner               = "sre-team"
  cost_center         = "CC-5678"
  project             = "api-gateway"
  data_classification = "confidential"

  additional_tags = {
    team       = "backend"
    department = "engineering"
  }
}
```

### Feeding tags into other modules

```hcl
module "vnet" {
  source              = "../az-virtual-network"
  resource_group_name = "rg-network-prod"
  location            = "eastus2"

  vnets = {
    hub = {
      name          = "vnet-hub-prod"
      address_space = ["10.0.0.0/16"]
      tags          = module.tags.tags
      subnets = {
        app  = { address_prefixes = ["10.0.1.0/24"] }
        data = { address_prefixes = ["10.0.2.0/24"] }
      }
    }
  }
}

module "storage" {
  source              = "../az-storage-account"
  resource_group_name = "rg-data-prod"
  location            = "eastus2"
  name                = "stproddata001"
  tags                = module.tags.tags
}
```

## Override Protection

Additional tags cannot override required tags. The merge order ensures required tags always win:

```hcl
additional_tags = {
  environment = "hacked"   # ignored — required tag takes precedence
  team        = "backend"  # applied — not a required tag
}
```

## Outputs

| Output | Description |
| --- | --- |
| `tags` | Complete tag map (required + additional) for passing to resources |
| `required_tags` | Only the required tags, without any additional tags |

## Tests

Run the test suite:

```bash
cd az-tagging
terraform test
```

| Test file | What it covers |
| --- | --- |
| `tests/tags.tftest.hcl` | All required tags are present with correct values |
| `tests/validation.tftest.hcl` | Rejects empty owner, invalid environment, invalid data classification |
| `tests/merge.tftest.hcl` | Additional tags merge correctly, cannot override required tags |
