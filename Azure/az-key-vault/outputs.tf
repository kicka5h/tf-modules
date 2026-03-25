output "key_vaults" {
  description = "Map of Key Vaults created, keyed by the logical name"
  value = {
    for k, v in azurerm_key_vault.this : k => {
      id        = v.id
      name      = v.name
      vault_uri = v.vault_uri
      tenant_id = v.tenant_id
    }
  }
}

output "access_policies" {
  description = "Map of Key Vault access policies created, keyed by vault-policy logical name"
  value = {
    for k, v in azurerm_key_vault_access_policy.this : k => {
      id = v.id
    }
  }
}
