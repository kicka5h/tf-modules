# tf-modules

Consumable Terraform modules for Azure. No wrappers. All utility.

## Organization Setup Guide

This section explains how to implement these modules across a GitHub organization. The architecture uses three types of repos: this module repo, a blocked-hosts repo, and caller repos.

### Repo Architecture

```
github.com/<org>/
├── tf-modules/                    # THIS REPO
│   ├── Azure/                     # module source code (also split into individual repos)
│   │   ├── az-virtual-network/
│   │   ├── az-nsg/
│   │   ├── az-storage-account/
│   │   └── ...
│   ├── policies/                  # centralized OPA policies (single source of truth)
│   ├── scripts/                   # integration test runner
│   └── .github/workflows/         # reusable workflows
│       ├── terraform-pipeline.yml        # caller repo CI/CD
│       ├── module-ci.yml                 # module repo CI
│       └── blocklist-refresh.yml         # scheduled blocklist updates (per-module)
│
├── blocked-hosts/                 # CUSTOM BLOCKLISTS
│   ├── ip-blocklist.txt           # one CIDR per line
│   └── fqdn-blocklist.txt         # one domain per line
│
├── az-virtual-network/            # INDIVIDUAL MODULE REPOS (optional)
├── az-nsg/                        # mirrors Azure/<module> from tf-modules
├── az-storage-account/
├── ...
│
├── infra-networking/              # CALLER REPO (example)
│   ├── shared/                    # Terraform code
│   │   └── main.tf
│   ├── environments/
│   │   ├── dev/
│   │   ├── qa/
│   │   ├── stage/
│   │   └── prod/
│   └── .github/workflows/
│       ├── terraform.yml
│       └── blocklist-refresh.yml
│
└── infra-compute/                 # CALLER REPO (example)
    ├── shared/
    ├── environments/
    └── .github/workflows/
```

### Step 1: Create the tf-modules repo

This repo. Contains all module source code, OPA policies, and reusable workflows.

### Step 2: Create the blocked-hosts repo

Create `<org>/blocked-hosts` with two files at the root:

**`ip-blocklist.txt`** — custom IP CIDRs to block (one per line, `#` for comments):
```
# Known malicious scanner
198.51.100.0/24
# Compromised hosting range
203.0.113.0/24
```

**`fqdn-blocklist.txt`** — custom domains to block (one per line, `#` for comments):
```
# Phishing domains
malicious-login.example.com
*.phishing-site.net
```

These are consumed automatically by `az-nsg`, `az-firewall`, `az-application-gateway`, and `az-front-door`. Update these files to push blocklist changes across all infrastructure.

### Step 3: Split modules into individual repos (optional)

If modules need independent versioning, mirror each `Azure/<module>/` into its own repo. Each module repo gets:
- Module source code (root of repo)
- `.github/workflows/ci.yml` — calls the reusable `module-ci.yml` workflow
- Integration tests in `tests/integration/` run against LocalStack Azure

### Step 4: Configure org-level secrets

Set these secrets at the GitHub organization level so all repos inherit them:

| Secret | Purpose |
| --- | --- |
| `ARM_CLIENT_ID` | Azure service principal for Terraform |
| `ARM_CLIENT_SECRET` | Azure service principal secret |
| `ARM_SUBSCRIPTION_ID` | Target Azure subscription |
| `ARM_TENANT_ID` | Azure AD tenant |
| `LOCALSTACK_AUTH_TOKEN` | LocalStack token for integration tests |

For multi-subscription setups, use GitHub environment-level secrets instead (different credentials per dev/qa/stage/prod).

### Step 5: Configure GitHub environments

In each caller repo, create these GitHub environments:

| Environment | Required reviewers | Purpose |
| --- | --- | --- |
| `stage` | At least 1 reviewer | Approval gate before stage deployment |
| `prod` | At least 2 reviewers | Approval gate before prod deployment |

`dev` and `qa` deploy automatically on merge — no environment protection needed.

### Step 6: Create caller repos

Each caller repo deploys a logical group of infrastructure (e.g., networking, compute, data platform). Structure:

```
infra-networking/
├── shared/
│   ├── main.tf               # module calls
│   ├── variables.tf           # variable declarations
│   └── providers.tf           # provider config (azurerm)
├── environments/
│   ├── dev/
│   │   ├── backend.tf         # terraform { backend "azurerm" { ... } }
│   │   └── dev.tfvars         # environment-specific values
│   ├── qa/
│   │   ├── backend.tf
│   │   └── qa.tfvars
│   ├── stage/
│   │   ├── backend.tf
│   │   └── stage.tfvars
│   └── prod/
│       ├── backend.tf
│       └── prod.tfvars
└── .github/workflows/
    ├── terraform.yml           # copy from terraform-pipeline-caller-template.yml
    └── blocklist-refresh.yml   # copy from blocklist-refresh-caller-template.yml (if using blocklist modules)
```

**`shared/main.tf`** — IPAM feeds addresses into all networking modules:
```hcl
module "ipam" {
  source         = "git::https://github.com/<org>/tf-modules.git//Azure/az-ipam?ref=v1.0.0"
  root_cidrs     = var.ipam_root_cidrs
  reserved_cidrs = var.ipam_reserved_cidrs
  allocations    = { (var.environment) = var.ipam_allocation }
}

module "vnets" {
  source              = "git::https://github.com/<org>/tf-modules.git//Azure/az-virtual-network?ref=v1.0.0"
  resource_group_name = var.resource_group_name
  location            = var.location

  vnets = {
    for vnet_key, vnet in var.ipam_allocation.vnets : vnet_key => {
      name          = "vnet-${var.environment}-${vnet_key}"
      address_space = module.ipam.vnet_cidrs["${var.environment}-${vnet_key}"].address_space
      subnets = {
        for sk, sv in vnet.subnets : sk => {
          address_prefixes = module.ipam.subnet_cidrs["${var.environment}-${vnet_key}-${sk}"].address_prefixes
        }
      }
    }
  }
}
```

The caller never writes a CIDR — IPAM calculates all addresses. See `examples/full-stack/` for the complete implementation including NSGs, route tables, and auto-association.

**`environments/dev/backend.tf`**:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformdev"
    container_name       = "tfstate"
    key                  = "networking.tfstate"
  }
}
```

**`environments/dev/dev.tfvars`** — defines the shape, not the addresses:
```hcl
resource_group_name = "rg-networking-dev"
location            = "eastus2"
environment         = "dev"

ipam_allocation = {
  cidr_newbits = 8      # /16 for this environment
  cidr_index   = 0      # first /16 from the root /8
  vnets = {
    hub = {
      cidr_newbits = 4   # /20
      cidr_index   = 0
      subnets = {
        GatewaySubnet       = { cidr_newbits = 4, cidr_index = 0 }  # /24
        AzureFirewallSubnet = { cidr_newbits = 4, cidr_index = 1 }  # /24
        management          = { cidr_newbits = 4, cidr_index = 2 }  # /24
      }
    }
    spoke = {
      cidr_newbits = 4
      cidr_index   = 1
      subnets = {
        app  = { cidr_newbits = 2, cidr_index = 0 }  # /22
        data = { cidr_newbits = 4, cidr_index = 4 }  # /24
        aks  = { cidr_newbits = 2, cidr_index = 2 }  # /22
      }
    }
  }
}

tags = { environment = "dev" }
```

### Step 7: Discover existing IP allocations

Before deploying, run the discovery script to find CIDRs already in use:

```bash
az login
./scripts/discover-ip-allocations.sh --tfvars > environments/dev/reserved.auto.tfvars
```

This generates `ipam_reserved_cidrs` from all existing VNets/subnets across the tenant. Terraform auto-loads `.auto.tfvars` files. The IPAM module validates that new allocations don't overlap with these reserved ranges.

Run this periodically or before major changes. If infrastructure is managed entirely through these modules, the reserved list only needs to cover resources created outside of Terraform.

### Step 8: Set up blocklist refresh (caller repos using blocklist modules)

Copy the blocklist refresh caller template to any caller repo that uses `az-nsg`, `az-firewall`, `az-application-gateway`, or `az-front-door`:

```yaml
# .github/workflows/blocklist-refresh.yml
name: Blocklist Refresh
on:
  schedule:
    - cron: "0 */6 * * *"
  workflow_dispatch:
jobs:
  refresh:
    uses: <org>/<repo>/.github/workflows/blocklist-refresh.yml@main
    with:
      terraform_directory: "shared"
      terraform_version: "1.9.0"
      auto_apply: false
    secrets:
      ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
```

## What Gets Enforced

### Module-level enforcement (built into module code)

These cannot be bypassed without modifying the module source:

| Enforcement | Modules |
| --- | --- |
| Spamhaus DROP/EDROP IP blocklist | az-nsg, az-firewall, az-application-gateway, az-front-door |
| Ultimate Hosts Blacklist FQDN blocklist | az-firewall, az-front-door |
| Custom org IP/FQDN blocklists | az-nsg, az-firewall, az-application-gateway, az-front-door |
| HTTPS only (validated) | az-storage-account, az-app-service |
| TLS 1.2 minimum (validated) | az-storage-account, az-app-service |
| Public network access disabled (validated) | az-storage-account, az-key-vault, az-container-registry, az-aks, az-app-service |
| Private cluster required (validated) | az-aks |
| No public FQDN on AKS (validated) | az-aks |
| RBAC required (validated) | az-aks |
| Admin user disabled (validated) | az-container-registry |
| Purge protection required (validated) | az-key-vault |
| FTP disabled (validated) | az-app-service |
| Remote debugging disabled (validated) | az-app-service |
| Private IP only (validated) | az-container-instance |
| Trusted launch (default) | az-virtual-machine, az-vmss |
| System-assigned managed identity (default) | az-virtual-machine, az-vmss, az-aks, az-container-instance, az-container-registry, az-key-vault, az-storage-account, az-app-service |
| Default `Terraform = "true"` tag | All modules |
| WAF policy with IP blocklist on WAF_v2 | az-application-gateway |
| WAF policy with IP + FQDN blocklist on Premium | az-front-door |
| Strong crypto required (validated) | az-vpn-gateway (rejects DES, DES3, MD5) |

### Pipeline-level enforcement (via OPA policies)

Enforced by the Terraform pipeline workflow at plan time:

| Policy | dev/qa | stage/prod |
| --- | --- | --- |
| Resource deletion protection | Skipped | Enforced |
| Resource replacement protection | Skipped | Enforced |

### Priority reservations

Modules that auto-generate rules reserve low-priority ranges:

| Module | Reserved | Caller starts at |
| --- | --- | --- |
| `az-nsg` | 100-199 (blocklist rules) | 200 |
| `az-firewall` | 100-299 (blocklist rule collection groups) | 300 |
| `az-front-door` | 1-99 (WAF custom rules) | 100 |

## Available Modules

### Networking (13 modules)

| Module | Resources |
| --- | --- |
| `az-dns-zone` | Public/private DNS zones, VNet links |
| `az-virtual-network` | VNets, subnets, delegations, DDoS, encryption |
| `az-route-table` | Route tables, routes, subnet associations |
| `az-nsg` | NSGs, security rules, subnet associations, IP blocklist |
| `az-public-ip` | Public IPs, IP prefixes |
| `az-nat-gateway` | NAT gateways, PIP/prefix/subnet associations |
| `az-firewall` | Firewalls, policies, rule collections, IP + FQDN blocklists |
| `az-application-gateway` | App gateways, WAF policies with IP blocklist |
| `az-load-balancer` | Load balancers, backend pools, probes, rules |
| `az-private-endpoint` | Private endpoints with mandatory DNS zone groups |
| `az-front-door` | Front Door profiles, endpoints, origins, routes, WAF with IP + FQDN blocklist |
| `az-vpn-gateway` | VPN gateways, local gateways, connections, IPsec policies |
| `az-expressroute` | ExpressRoute circuits, peerings |

### Compute (5 modules)

| Module | Resources |
| --- | --- |
| `az-virtual-machine` | Linux/Windows VMs, NICs, data disks |
| `az-vmss` | Linux/Windows scale sets, rolling upgrades |
| `az-aks` | AKS clusters, node pools |
| `az-container-instance` | Container groups |
| `az-container-registry` | Container registries, georeplications |

### Storage (2 modules)

| Module | Resources |
| --- | --- |
| `az-storage-account` | Storage accounts, containers, file shares, queues, tables |
| `az-key-vault` | Key Vaults, access policies |

### App Platform (1 module)

| Module | Resources |
| --- | --- |
| `az-app-service` | Service plans, Linux/Windows web apps |

### IP Address Management (1 module)

| Module | Purpose |
| --- | --- |
| `az-ipam` | Algorithmic CIDR allocation with existing infrastructure discovery and overlap detection |

The IPAM module generates non-overlapping IP address spaces from a root CIDR block. A companion discovery script (`scripts/discover-ip-allocations.sh`) queries Azure Resource Graph for all existing VNets, subnets, and public IPs across the tenant. New allocations are validated against these reserved ranges to prevent conflicts.

IPAM is designed to be consumed by other modules — the caller defines the shape of their network (VNet names, subnet names, sizes) and IPAM feeds calculated CIDRs into `az-virtual-network`, `az-nsg`, `az-route-table`, and any other module that needs addresses. The caller never writes a CIDR. See `examples/full-stack/` for a complete reference implementation.

**How it flows:**

```
Caller .tfvars (shape only)     IPAM module              Networking modules
┌─────────────────────────┐    ┌──────────────────┐    ┌───────────────────┐
│ ipam_allocation = {     │    │                  │    │ az-virtual-network│
│   cidr_newbits = 8      │───>│  cidrsubnet()    │───>│   vnets + subnets │
│   cidr_index   = 0      │    │  overlap check   │    │                   │
│   vnets = {             │    │  reserved CIDRs  │    ├───────────────────┤
│     hub = { subnets }   │    │                  │    │ az-nsg            │
│     spoke = { subnets } │    └──────────────────┘    │   auto-associate  │
│   }                     │                            ├───────────────────┤
│ }                       │                            │ az-route-table    │
│ nsg_rules = { ... }     │───────────────────────────>│   auto-associate  │
│ route_tables = { ... }  │                            └───────────────────┘
└─────────────────────────┘
```

## Resources Not Modularized

The following Azure resources were intentionally skipped. A module should enforce meaningful policy, configuration standards, or security defaults. Resources that would just pass variables through to a single Terraform resource with no added value are better used directly.

### Networking

| Resource | Why skipped |
| --- | --- |
| VNet Peering | Single resource with a few booleans. No configuration to standardize — each peering is unique to the topology. |
| Bastion Host | Single resource, SKU-specific fields. No policy value beyond what the caller sets. |
| DDoS Protection Plan | One resource, one `name` field. The `az-virtual-network` module already accepts `ddos_protection_plan.id` as input. |
| Network Watcher | Azure auto-creates one per region. A module adds no value over the auto-provisioned resource. |
| Traffic Manager | Configuration varies too much per use case (geographic routing, performance, priority). No meaningful defaults to enforce. |
| Private Link Service | Straightforward resource. Config is highly specific to each service being exposed. |

### Compute

| Resource | Why skipped |
| --- | --- |
| Availability Sets | Legacy construct, replaced by availability zones. All compute modules default to zone-redundant deployments. |
| Proximity Placement Groups | Single resource with no security or configuration to enforce. |
| Dedicated Hosts | Niche use case. Config is straightforward and host-specific. |
| Batch Accounts | Niche workload type. No org-wide defaults to enforce. |

### General

| Resource | Why skipped |
| --- | --- |
| Resource Groups | Trivial single resource. Often created by other automation or landing zone tooling. |
| User-Assigned Managed Identity | Single resource. All modules that need identity default to SystemAssigned. User-assigned identities are created directly when needed. |
| Role Assignments | Highly specific to each workload. A module would just be a wrapper around `azurerm_role_assignment` with no added policy. |
| Log Analytics Workspace | Single resource. Usually provisioned once per environment by a platform team, then referenced by ID. |
| Monitor Diagnostic Settings | Attached per-resource with unique log categories. A module can't generalize this without becoming more complex than the resource itself. |

### Database

| Resource | Why skipped (for now) |
| --- | --- |
| Azure SQL Database | Good candidate for a future module (enforce TLS, private endpoints, backup policies, geo-redundancy). Not yet built. |
| Cosmos DB | Good candidate for a future module (enforce consistency level, private endpoints, backup type). Not yet built. |
| Redis Cache | Good candidate for a future module (enforce TLS, private endpoints, minimum SKU). Not yet built. |

Database modules are the most likely next addition. The pattern would follow `az-storage-account` — enforce encryption, private network access, and backup policies via validation.

## Centralized OPA Policies

All OPA policies are hosted in `policies/` in this repo. The Terraform pipeline automatically checks out and evaluates these policies — caller repos do not need their own copies.

### Writing Policies

```rego
package terraform.dns

import rego.v1

denied_resource_types := {
  "azurerm_dns_zone",
  "azurerm_private_dns_zone",
}

deny contains msg if {
  some rc in input.resource_changes
  rc.type in denied_resource_types
  "delete" in rc.change.actions
  msg := sprintf("Deletion of %s '%s' is not allowed.", [rc.type, rc.address])
}
```

### Testing Policies

```bash
opa test policies/ -v
```

## Terraform Pipeline

A reusable CI/CD workflow at `.github/workflows/terraform-pipeline.yml`.

### Pipeline Behavior

| Trigger | What runs | Deploys? |
| --- | --- | --- |
| PR opened/updated | validate + plan + OPA check | No |
| PR merged to main | validate + plan + OPA check + apply | Yes |

### Change Detection

- Changes to `shared/` trigger ALL environments
- Changes to `environments/<env>/` trigger only that environment

### Environment Deployment

| Environment | Auto-deploy | Approval required | Deletion policies |
| --- | --- | --- | --- |
| dev | Yes | No | Skipped |
| qa | Yes | No | Skipped |
| stage | After qa | Yes | Enforced |
| prod | After stage | Yes | Enforced |

## Blocklist Refresh Pipeline

Modules with blocklists fetch external lists at `terraform plan` time. A scheduled workflow detects changes and triggers deployments.

| Module | Spamhaus DROP/EDROP | Ultimate Hosts | Custom org IP | Custom org FQDN |
| --- | --- | --- | --- | --- |
| `az-nsg` | Yes | - | Yes | - |
| `az-firewall` | Yes | Yes | Yes | Yes |
| `az-application-gateway` | Yes | - | Yes | - |
| `az-front-door` | Yes | Yes | Yes | Yes |

Each blocklist module includes its own workflow under `.github/workflows/`. Recommended schedule: every 6 hours.

## Module CI (Integration Tests with LocalStack)

A reusable CI workflow at `.github/workflows/module-ci.yml` runs on every PR/push to module repos.

| Job | What | Requires LocalStack |
| --- | --- | --- |
| Lint | `terraform fmt -check -recursive` | No |
| Unit Tests | `terraform test` (mock_provider, plan-only) | No |
| Integration Tests | `terraform test` (real provider, apply + destroy against LocalStack) | Yes |
| OPA Tests | `opa test policies/ -v` | No |

### Test file naming convention

All tests live in the `tests/` directory. The filename prefix determines how they run:

| Pattern | Type | Provider | Command | When it runs |
| --- | --- | --- | --- | --- |
| `tests/*.tftest.hcl` | Unit | `mock_provider "azurerm" {}` | `plan` | Always (no infra needed) |
| `tests/integration_*.tftest.hcl` | Integration | Real `azurerm` pointing at LocalStack | `apply` | Only when LocalStack is running |

The CI workflow automatically separates them — unit tests exclude `integration_*` files, integration tests only run `integration_*` files.

### Test structure

Each module with integration tests has:

```
az-virtual-network/
├── tests/
│   ├── vnets.tftest.hcl              # unit test (mock_provider, plan)
│   ├── tags.tftest.hcl               # unit test
│   ├── empty.tftest.hcl              # unit test
│   ├── validation.tftest.hcl         # unit test
│   ├── integration_vnet.tftest.hcl   # integration test (real provider, apply)
│   └── setup/
│       └── main.tf                   # creates resource group for integration tests
└── ...
```

Integration tests use a two-step pattern:

1. **Setup run**: creates the resource group via a helper module in `tests/setup/`
2. **Apply run**: applies the module and asserts on the created resources

Terraform's test framework handles cleanup automatically — resources are destroyed after the test completes.

### Modules with integration tests

| Module | Test file | What it applies |
| --- | --- | --- |
| `az-virtual-network` | `integration_vnet.tftest.hcl` | VNet + 2 subnets, validates tags |
| `az-nsg` | `integration_nsg.tftest.hcl` | NSG + 2 user rules, validates priority and access |
| `az-route-table` | `integration_route_table.tftest.hcl` | Route table + 2 routes, validates BGP and next hop |
| `az-storage-account` | `integration_storage.tftest.hcl` | Storage account + containers + file share, validates TLS and replication |
| `az-key-vault` | `integration_keyvault.tftest.hcl` | Key Vault, validates SKU, purge protection, RBAC, public access |

### Integration test provider config

Every `integration_*.tftest.hcl` file includes this provider block targeting LocalStack:

```hcl
provider "azurerm" {
  features {}
  subscription_id                 = "00000000-0000-0000-0000-000000000000"
  tenant_id                       = "00000000-0000-0000-0000-000000000000"
  client_id                       = "00000000-0000-0000-0000-000000000000"
  client_secret                   = "mock-secret"
  metadata_host                   = "localhost.localstack.cloud:4566"
  resource_provider_registrations = "none"
}
```

### Adding integration tests to a new module

1. Create `tests/setup/main.tf` with a resource group:
    ```hcl
    resource "azurerm_resource_group" "test" {
      name     = "rg-<module>-inttest"
      location = "eastus2"
    }
    ```

2. Create `tests/integration_<name>.tftest.hcl` with:
    - The LocalStack provider block (above)
    - Variables for a minimal module invocation
    - A `run "setup_resource_group"` block with `command = apply` and `module { source = "./tests/setup" }`
    - A `run "apply_<name>_module"` block with `command = apply` and assertions

3. The CI workflow picks it up automatically — no workflow changes needed.

### Running locally

```bash
# Start LocalStack Azure
IMAGE_NAME=localstack/localstack-azure-alpha localstack start

# Run all tests (unit + integration) via terraform test
cd Azure/az-virtual-network
terraform init
terraform test

# Run only unit tests (no LocalStack needed)
terraform test --filter=vnets
terraform test --filter=tags

# Run only integration tests (requires LocalStack)
terraform test --filter=integration_vnet

# Run all integration tests via the helper script
./scripts/integration-test.sh

# Run a single module via the helper script
./scripts/integration-test.sh az-virtual-network
```

### CI setup per module repo

1. Copy `.github/workflows/module-ci-caller-template.yml` to the module repo as `.github/workflows/ci.yml`
2. Add `LOCALSTACK_AUTH_TOKEN` as a repository secret (get from [app.localstack.cloud](https://app.localstack.cloud))
3. The workflow automatically detects and runs both unit and integration tests
