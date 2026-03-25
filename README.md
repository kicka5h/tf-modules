# tf-modules
Consumable modules for Terraform. No wrappers. All utility.

## Enforcing OPA Policies in Caller Repos

Modules in this repo define infrastructure building blocks. Policy enforcement belongs in the caller repo, where `terraform plan` output is available and environment-specific rules can be applied.

### Caller Repo Structure

```
caller-repo/
├── main.tf
├── policies/
│   ├── dns/
│   │   └── deny_zone_deletion.rego
│   ├── compute/
│   │   └── deny_instance_downsize.rego
│   └── ...
└── .github/workflows/
    └── terraform.yml
```

Organize policies by module or domain under a `policies/` directory. Each subdirectory maps to a module you consume.

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
