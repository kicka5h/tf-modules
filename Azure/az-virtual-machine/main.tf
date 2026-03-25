locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)

  # Split VMs by OS type
  linux_vms = {
    for k, vm in var.virtual_machines : k => vm
    if vm.os_type == "linux"
  }

  windows_vms = {
    for k, vm in var.virtual_machines : k => vm
    if vm.os_type == "windows"
  }

  # Flatten data disks across all VMs
  data_disks = {
    for item in flatten([
      for vm_key, vm in var.virtual_machines : [
        for disk_key, disk in vm.data_disks : {
          key                    = "${vm_key}-${disk_key}"
          vm_key                 = vm_key
          os_type                = vm.os_type
          name                   = disk.name
          storage_account_type   = disk.storage_account_type
          disk_size_gb           = disk.disk_size_gb
          caching                = disk.caching
          lun                    = disk.lun
          create_option          = disk.create_option
          disk_encryption_set_id = disk.disk_encryption_set_id
          zone                   = vm.zone
          tags                   = merge(local.tags, vm.tags)
        }
      ]
    ]) : item.key => item
  }
}

# --- Network Interfaces (one per VM) ---

resource "azurerm_network_interface" "this" {
  for_each = var.virtual_machines

  name                = "${each.value.name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = merge(local.tags, each.value.tags)

  ip_configuration {
    name                          = "internal"
    subnet_id                     = each.value.subnet_id
    private_ip_address_allocation = each.value.private_ip_address_allocation
    private_ip_address            = each.value.private_ip_address
    public_ip_address_id          = each.value.public_ip_address_id
  }
}

# --- Linux Virtual Machines ---

resource "azurerm_linux_virtual_machine" "this" {
  for_each = local.linux_vms

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = each.value.size
  zone                = each.value.zone
  admin_username      = each.value.admin_username
  admin_password      = each.value.admin_password
  tags                = merge(local.tags, each.value.tags)

  disable_password_authentication = each.value.admin_ssh_key != null ? true : false

  network_interface_ids = [
    azurerm_network_interface.this[each.key].id,
  ]

  dynamic "admin_ssh_key" {
    for_each = each.value.admin_ssh_key != null ? [each.value.admin_ssh_key] : []
    content {
      username   = each.value.admin_username
      public_key = admin_ssh_key.value.public_key
    }
  }

  os_disk {
    caching                = each.value.os_disk.caching
    storage_account_type   = each.value.os_disk.storage_account_type
    disk_size_gb           = each.value.os_disk.disk_size_gb
    disk_encryption_set_id = each.value.os_disk.disk_encryption_set_id
  }

  source_image_reference {
    publisher = each.value.source_image_reference.publisher
    offer     = each.value.source_image_reference.offer
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }

  boot_diagnostics {
    storage_account_uri = each.value.boot_diagnostics.storage_account_uri
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  secure_boot_enabled        = each.value.secure_boot_enabled
  vtpm_enabled               = each.value.vtpm_enabled
  encryption_at_host_enabled = each.value.encryption_at_host_enabled
  patch_mode                 = each.value.patch_mode
}

# --- Windows Virtual Machines ---

resource "azurerm_windows_virtual_machine" "this" {
  for_each = local.windows_vms

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = each.value.size
  zone                = each.value.zone
  admin_username      = each.value.admin_username
  admin_password      = each.value.admin_password
  tags                = merge(local.tags, each.value.tags)

  network_interface_ids = [
    azurerm_network_interface.this[each.key].id,
  ]

  os_disk {
    caching                = each.value.os_disk.caching
    storage_account_type   = each.value.os_disk.storage_account_type
    disk_size_gb           = each.value.os_disk.disk_size_gb
    disk_encryption_set_id = each.value.os_disk.disk_encryption_set_id
  }

  source_image_reference {
    publisher = each.value.source_image_reference.publisher
    offer     = each.value.source_image_reference.offer
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }

  boot_diagnostics {
    storage_account_uri = each.value.boot_diagnostics.storage_account_uri
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  secure_boot_enabled        = each.value.secure_boot_enabled
  vtpm_enabled               = each.value.vtpm_enabled
  encryption_at_host_enabled = each.value.encryption_at_host_enabled
  patch_mode                 = each.value.patch_mode
}

# --- Managed Data Disks ---

resource "azurerm_managed_disk" "this" {
  for_each = local.data_disks

  name                   = each.value.name
  location               = var.location
  resource_group_name    = var.resource_group_name
  storage_account_type   = each.value.storage_account_type
  disk_size_gb           = each.value.disk_size_gb
  create_option          = each.value.create_option
  zone                   = each.value.zone
  disk_encryption_set_id = each.value.disk_encryption_set_id
  tags                   = each.value.tags
}

# --- Data Disk Attachments ---

resource "azurerm_virtual_machine_data_disk_attachment" "this" {
  for_each = local.data_disks

  managed_disk_id = azurerm_managed_disk.this[each.key].id
  virtual_machine_id = (
    each.value.os_type == "linux"
    ? azurerm_linux_virtual_machine.this[each.value.vm_key].id
    : azurerm_windows_virtual_machine.this[each.value.vm_key].id
  )
  lun     = each.value.lun
  caching = each.value.caching
}
