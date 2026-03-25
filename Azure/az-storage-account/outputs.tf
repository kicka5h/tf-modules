output "storage_accounts" {
  description = "Map of storage accounts created, keyed by the logical name"
  value = {
    for k, v in azurerm_storage_account.this : k => {
      id                        = v.id
      name                      = v.name
      primary_blob_endpoint     = v.primary_blob_endpoint
      primary_connection_string = v.primary_connection_string
      identity = try({
        principal_id = v.identity[0].principal_id
      }, null)
    }
  }
  sensitive = true
}

output "containers" {
  description = "Map of storage containers created, keyed by storage_account-container logical name"
  value = {
    for k, v in azurerm_storage_container.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "file_shares" {
  description = "Map of file shares created, keyed by storage_account-share logical name"
  value = {
    for k, v in azurerm_storage_share.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "queues" {
  description = "Map of storage queues created, keyed by storage_account-queue logical name"
  value = {
    for k, v in azurerm_storage_queue.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "tables" {
  description = "Map of storage tables created, keyed by storage_account-table logical name"
  value = {
    for k, v in azurerm_storage_table.this : k => {
      id   = v.id
      name = v.name
    }
  }
}
