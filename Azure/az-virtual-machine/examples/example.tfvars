resource_group_name = "rg-compute"
location            = "eastus2"

virtual_machines = {
  web = {
    name           = "vm-web-01"
    os_type        = "linux"
    size           = "Standard_D2s_v3"
    zone           = "1"
    admin_username = "azureadmin"
    admin_ssh_key = {
      public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB..."
    }
    subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-main/subnets/web"
    source_image_reference = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
      version   = "latest"
    }
    os_disk = {
      caching              = "ReadWrite"
      storage_account_type = "Premium_LRS"
      disk_size_gb         = 64
    }
    data_disks = {
      app = {
        name         = "vm-web-01-app"
        disk_size_gb = 128
        lun          = 0
      }
    }
    tags = {
      role = "webserver"
    }
  }

  dc = {
    name           = "vm-dc-01"
    os_type        = "windows"
    size           = "Standard_D4s_v3"
    zone           = "2"
    admin_username = "azureadmin"
    admin_password = "P@ssw0rd1234!"
    subnet_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-main/subnets/ad"
    source_image_reference = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-g2"
      version   = "latest"
    }
    data_disks = {
      ntds = {
        name         = "vm-dc-01-ntds"
        disk_size_gb = 64
        lun          = 0
      }
      sysvol = {
        name         = "vm-dc-01-sysvol"
        disk_size_gb = 32
        lun          = 1
      }
    }
    tags = {
      role = "domain-controller"
    }
  }
}

tags = {
  environment = "production"
  managed_by  = "terraform"
}
