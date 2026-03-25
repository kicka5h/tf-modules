output "virtual_machines" {
  description = "Map of virtual machines created, keyed by the logical name"
  value = merge(
    {
      for k, v in azurerm_linux_virtual_machine.this : k => {
        id                 = v.id
        name               = v.name
        private_ip_address = v.private_ip_address
      }
    },
    {
      for k, v in azurerm_windows_virtual_machine.this : k => {
        id                 = v.id
        name               = v.name
        private_ip_address = v.private_ip_address
      }
    },
  )
}

output "network_interfaces" {
  description = "Map of network interfaces created, keyed by the logical VM name"
  value = {
    for k, v in azurerm_network_interface.this : k => {
      id             = v.id
      name           = v.name
      private_ip_address = v.private_ip_address
    }
  }
}

output "data_disks" {
  description = "Map of managed data disks created, keyed by vm-disk logical name"
  value = {
    for k, v in azurerm_managed_disk.this : k => {
      id   = v.id
      name = v.name
    }
  }
}
