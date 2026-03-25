resource_group_name = "rg-security"
location            = "eastus2"

key_vaults = {
  # Vault using RBAC authorization (recommended) with network ACLs
  main = {
    name                      = "kv-production-main"
    enable_rbac_authorization = true
    network_acls = {
      default_action = "Deny"
      bypass         = "AzureServices"
      ip_rules       = ["203.0.113.0/24"]
      virtual_network_subnet_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-prod/subnets/workload",
      ]
    }
    tags = {
      team = "platform"
    }
  }

  # Vault using access policies for legacy workloads
  legacy = {
    name                      = "kv-production-legacy"
    enable_rbac_authorization = false
    access_policies = {
      app_service = {
        object_id          = "11111111-1111-1111-1111-111111111111"
        secret_permissions = ["Get", "List"]
      }
      deploy_pipeline = {
        object_id               = "22222222-2222-2222-2222-222222222222"
        key_permissions         = ["Get", "List", "Create", "Import"]
        secret_permissions      = ["Get", "List", "Set", "Delete"]
        certificate_permissions = ["Get", "List", "Create", "Import"]
      }
    }
  }
}

tags = {
  environment = "production"
  managed_by  = "terraform"
}
