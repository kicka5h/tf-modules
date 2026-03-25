resource_group_name = "rg-storage"
location            = "eastus2"

storage_accounts = {
  primary = {
    name                     = "stprodprimary001"
    account_replication_type = "GRS"
    network_rules = {
      default_action = "Deny"
      bypass         = ["AzureServices"]
      ip_rules       = ["203.0.113.0/24"]
      virtual_network_subnet_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-main/subnets/workload",
      ]
    }
    containers = {
      data = {
        name = "data"
      }
      backups = {
        name = "backups"
      }
      logs = {
        name = "logs"
      }
    }
    file_shares = {
      config = {
        name  = "config"
        quota = 100
      }
      uploads = {
        name  = "uploads"
        quota = 250
      }
    }
    queues = {
      processing = {
        name = "processing"
      }
      notifications = {
        name = "notifications"
      }
    }
    tables = {
      events = {
        name = "events"
      }
    }
  }

  minimal = {
    name = "stprodminimal001"
  }
}

tags = {
  environment = "production"
  managed_by  = "terraform"
}
