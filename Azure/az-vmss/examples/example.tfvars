resource_group_name = "rg-compute"
location            = "eastus2"

scale_sets = {
  web = {
    name           = "vmss-web-linux"
    os_type        = "linux"
    sku            = "Standard_D2s_v5"
    instances      = 3
    zones          = ["1", "2", "3"]
    admin_username = "azureadmin"
    admin_ssh_key = {
      public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ..."
    }
    source_image_reference = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
      version   = "latest"
    }
    os_disk = {
      caching              = "ReadWrite"
      storage_account_type = "Premium_LRS"
    }
    network_interface = {
      name      = "nic-web"
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-networking/providers/Microsoft.Network/virtualNetworks/vnet-main/subnets/snet-web"
    }
    upgrade_mode = "Rolling"
    rolling_upgrade_policy = {
      max_batch_instance_percent              = 20
      max_unhealthy_instance_percent          = 20
      max_unhealthy_upgraded_instance_percent = 20
      pause_time_between_batches              = "PT2S"
    }
    automatic_os_upgrade_policy = {
      enable_automatic_os_upgrade = true
    }
    tags = {
      Role = "web"
    }
  }

  app = {
    name           = "vmss-app-windows"
    os_type        = "windows"
    sku            = "Standard_D4s_v5"
    instances      = 2
    zones          = ["1", "2"]
    admin_username = "azureadmin"
    admin_password = "P@ssw0rd1234!"
    source_image_reference = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-azure-edition"
      version   = "latest"
    }
    network_interface = {
      name      = "nic-app"
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-networking/providers/Microsoft.Network/virtualNetworks/vnet-main/subnets/snet-app"
    }
    data_disks = {
      data01 = {
        storage_account_type = "Premium_LRS"
        disk_size_gb         = 128
        caching              = "ReadOnly"
        lun                  = 0
      }
    }
    tags = {
      Role = "app"
    }
  }
}

tags = {
  Environment = "production"
  Team        = "platform"
}
