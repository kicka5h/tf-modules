# tf-modules
Consumable modules for Terraform. No wrappers. All utility.

## Centralized OPA Policies

All OPA policies are hosted centrally in this repo under `policies/`. Caller repos do NOT need their own copies — the Terraform pipeline workflow checks out this repo and evaluates policies automatically.

```
tf-modules/
├── policies/                  # all OPA policies live here
│   ├── deny_vm_deletion.rego
│   ├── deny_vnet_deletion.rego
│   ├── deny_storage_account_deletion.rego
│   └── ...
├── .github/workflows/
│   ├── terraform-pipeline.yml            # reusable CI/CD pipeline
│   ├── terraform-pipeline-caller-template.yml
│   └── blocklist-refresh-caller-template.yml
└── Azure/                     # modules (each also its own repo)
```

Each module also keeps a copy of its policy in its own `policies/` directory for reference, but the centralized `policies/` directory is the single source of truth used by the pipeline.

### Writing Policies

Policies evaluate against Terraform plan JSON output. Each policy file should:

1. Define a `package` (e.g., `package terraform.dns`)
2. Inspect `input.resource_changes` for the resource types the module manages
3. Populate a `deny` set with error messages when a violation is found

Example for the `az-dns-zone` module:

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

Write OPA unit tests alongside each policy (e.g., `deny_zone_deletion_test.rego`) and run them with:

```bash
opa test policies/ -v
```

### CI/CD Integration

Add a policy check step between `plan` and `apply` in your pipeline. Example GitHub Actions workflow:

```yaml
jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3

      - name: Terraform Plan
        run: |
          terraform init
          terraform plan -out=tfplan
          terraform show -json tfplan > tfplan.json

      - name: OPA Policy Check
        uses: open-policy-agent/setup-opa@v2
      - run: |
          opa eval \
            -i tfplan.json \
            -d policies/ \
            --fail-defined \
            "data.terraform[_].deny[x]"

      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply tfplan
```

Alternatively, use [conftest](https://www.conftest.dev/) which is purpose-built for this:

```bash
conftest test tfplan.json -p policies/
```

### Per-Module Policy Checklist

When consuming a new module, consider adding policies for:

| Concern | Example |
| --- | --- |
| Prevent resource deletion | Block destroy of DNS zones, databases, storage accounts |
| Prevent resource replacement | Block delete+create cycles on stateful resources |
| Enforce tagging | Require specific tags on all resources |
| Restrict configuration | Enforce SKU tiers, region constraints, naming conventions |

Each module's directory in this repo may include a `policies/` folder with reference policies. Copy and adapt them to your caller repo as needed — they are not enforced from within the module.

## Blocklist Refresh Pipeline

The following modules automatically fetch and enforce external IP and FQDN blocklists at `terraform plan` time:

| Module | Spamhaus DROP/EDROP | Ultimate Hosts Blacklist | Custom org IP list | Custom org FQDN list |
| --- | --- | --- | --- | --- |
| `az-nsg` | Yes | - | Yes | - |
| `az-firewall` | Yes | Yes | Yes | Yes |
| `az-application-gateway` | Yes | - | Yes | - |
| `az-front-door` | Yes | Yes | Yes | Yes |

These lists change over time. To keep your infrastructure up to date, set up a scheduled pipeline in your caller repo that periodically runs `terraform plan` and applies changes when the lists have updated.

### Using the Reusable Workflow

This repo provides a reusable GitHub Actions workflow at `.github/workflows/blocklist-refresh.yml`. Add this to your caller repo:

```yaml
# .github/workflows/blocklist-refresh.yml
name: Blocklist Refresh

on:
  schedule:
    # Run every 6 hours
    - cron: "0 */6 * * *"
  workflow_dispatch:

jobs:
  refresh:
    uses: <org>/tf-modules/.github/workflows/blocklist-refresh.yml@main
    with:
      terraform_directory: "."
      terraform_version: "1.9.0"
      auto_apply: false  # set to true for automatic deployment
    secrets:
      ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
```

### How It Works

1. **Check phase**: Fetches each blocklist URL, computes a SHA-256 hash, and compares against cached hashes from the previous run
2. **Deploy phase** (only if changes detected): Runs `terraform plan` to detect drift from updated lists, then optionally applies
3. **Summary**: Reports which lists changed and whether changes were applied

### Configuration

| Input | Default | Description |
| --- | --- | --- |
| `terraform_directory` | (required) | Path to your Terraform root module |
| `terraform_version` | `latest` | Terraform CLI version |
| `auto_apply` | `false` | Set to `true` to apply automatically; `false` requires manual approval via GitHub environment protection rules |

### Recommended Schedule

| Environment | Frequency | `auto_apply` |
| --- | --- | --- |
| Production | Every 6 hours | `false` (manual approval) |
| Staging | Every 6 hours | `true` |
| Development | Daily | `true` |

A full template is available at `.github/workflows/blocklist-refresh-caller-template.yml`.

Each blocklist module also includes its own copy of the workflow under `<module>/.github/workflows/` since modules are intended to be used as separate repos.

## Terraform Pipeline

A reusable CI/CD workflow is provided at `.github/workflows/terraform-pipeline.yml` for caller repos that deploy infrastructure using these modules.

### Expected Caller Repo Structure

```
caller-repo/
├── shared/                    # Terraform code (written once)
│   ├── main.tf
│   ├── variables.tf
│   └── providers.tf
├── environments/
│   ├── dev/
│   │   ├── backend.tf        # remote state config
│   │   └── dev.tfvars        # environment-specific values
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
    ├── terraform.yml          # calls the reusable pipeline
    └── blocklist-refresh.yml  # scheduled blocklist updates
```

- `shared/` contains the actual Terraform code — module calls, resources, providers. Written once.
- `environments/<env>/` contains only `backend.tf` (remote state) and `.tfvars` (variable values).
- The pipeline copies `backend.tf` into `shared/` and passes `.tfvars` via `-var-file`.
- OPA policies are hosted centrally in this repo — no `policies/` directory needed in caller repos.

### Pipeline Behavior

| Trigger | What runs | Deploys? |
| --- | --- | --- |
| PR opened/updated | validate + plan + OPA check on changed environments | No |
| PR merged to main | validate + plan + OPA check + apply on changed environments | Yes |

### Change Detection

- Changes to `shared/` trigger ALL environments (since shared code affects everything)
- Changes to `environments/<env>/` trigger only that environment

### Environment Deployment

| Environment | Auto-deploy | Approval required | Deletion policies enforced |
| --- | --- | --- | --- |
| dev | Yes | No | No |
| qa | Yes | No | No |
| stage | After qa succeeds | Yes (GitHub environment protection) | Yes |
| prod | After stage succeeds | Yes (GitHub environment protection) | Yes |

### OPA Policy Enforcement

- **dev/qa**: All OPA policies run except deletion/replacement denials — this allows destroy+recreate workflows during development
- **stage/prod**: ALL policies enforced including deletion protection — prevents accidental resource destruction

### Usage

Copy `.github/workflows/terraform-pipeline-caller-template.yml` to your caller repo and update:
- `<org>/<repo>` to your actual org/repo for both `uses` and `policies_repo`
- `terraform_version` to your version
- `shared_directory` and `environments_directory` if not using the defaults

### Prerequisites

1. GitHub environments `stage` and `prod` configured with [required reviewers](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#required-reviewers)
2. `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID` secrets configured at the repo or environment level
3. The policies repo (`tf-modules`) must be accessible to the caller repo's workflow (public, or use a PAT for private repos)
