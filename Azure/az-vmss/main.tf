locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)

  linux_vmss = {
    for k, v in var.scale_sets : k => v if v.os_type == "linux"
  }

  windows_vmss = {
    for k, v in var.scale_sets : k => v if v.os_type == "windows"
  }
}

resource "azurerm_linux_virtual_machine_scale_set" "this" {
  for_each = local.linux_vmss

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = each.value.sku
  instances           = each.value.instances
  zones               = each.value.zones
  admin_username      = each.value.admin_username
  admin_password      = each.value.admin_password

  disable_password_authentication = each.value.admin_ssh_key != null ? true : false

  dynamic "admin_ssh_key" {
    for_each = each.value.admin_ssh_key != null ? [each.value.admin_ssh_key] : []
    content {
      username   = each.value.admin_username
      public_key = admin_ssh_key.value.public_key
    }
  }

  source_image_reference {
    publisher = each.value.source_image_reference.publisher
    offer     = each.value.source_image_reference.offer
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }

  os_disk {
    caching                = each.value.os_disk.caching
    storage_account_type   = each.value.os_disk.storage_account_type
    disk_size_gb           = each.value.os_disk.disk_size_gb
    disk_encryption_set_id = each.value.os_disk.disk_encryption_set_id
  }

  network_interface {
    name                          = each.value.network_interface.name
    primary                       = each.value.network_interface.primary
    enable_accelerated_networking = each.value.network_interface.enable_accelerated_networking

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = each.value.network_interface.subnet_id
    }
  }

  boot_diagnostics {
    storage_account_uri = each.value.boot_diagnostics.storage_account_uri
  }

  identity {
    type         = each.value.identity.type
    identity_ids = each.value.identity.type == "UserAssigned" || each.value.identity.type == "SystemAssigned, UserAssigned" ? each.value.identity.identity_ids : []
  }

  secure_boot_enabled        = each.value.secure_boot_enabled
  vtpm_enabled               = each.value.vtpm_enabled
  encryption_at_host_enabled = each.value.encryption_at_host_enabled
  zone_balance               = each.value.zone_balance
  upgrade_mode               = each.value.upgrade_mode
  health_probe_id            = each.value.health_probe_id

  dynamic "rolling_upgrade_policy" {
    for_each = each.value.upgrade_mode == "Rolling" ? [each.value.rolling_upgrade_policy] : []
    content {
      max_batch_instance_percent              = rolling_upgrade_policy.value.max_batch_instance_percent
      max_unhealthy_instance_percent          = rolling_upgrade_policy.value.max_unhealthy_instance_percent
      max_unhealthy_upgraded_instance_percent = rolling_upgrade_policy.value.max_unhealthy_upgraded_instance_percent
      pause_time_between_batches              = rolling_upgrade_policy.value.pause_time_between_batches
    }
  }

  dynamic "automatic_instance_repair" {
    for_each = each.value.automatic_instance_repair != null ? [each.value.automatic_instance_repair] : []
    content {
      enabled      = automatic_instance_repair.value.enabled
      grace_period = automatic_instance_repair.value.grace_period
    }
  }

  dynamic "automatic_os_upgrade_policy" {
    for_each = each.value.automatic_os_upgrade_policy != null ? [each.value.automatic_os_upgrade_policy] : []
    content {
      disable_automatic_rollback  = automatic_os_upgrade_policy.value.disable_automatic_rollback
      enable_automatic_os_upgrade = automatic_os_upgrade_policy.value.enable_automatic_os_upgrade
    }
  }

  dynamic "data_disk" {
    for_each = each.value.data_disks
    content {
      storage_account_type   = data_disk.value.storage_account_type
      disk_size_gb           = data_disk.value.disk_size_gb
      caching                = data_disk.value.caching
      lun                    = data_disk.value.lun
      create_option          = data_disk.value.create_option
      disk_encryption_set_id = data_disk.value.disk_encryption_set_id
    }
  }

  tags = merge(local.tags, each.value.tags)
}

resource "azurerm_windows_virtual_machine_scale_set" "this" {
  for_each = local.windows_vmss

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = each.value.sku
  instances           = each.value.instances
  zones               = each.value.zones
  admin_username      = each.value.admin_username
  admin_password      = each.value.admin_password

  source_image_reference {
    publisher = each.value.source_image_reference.publisher
    offer     = each.value.source_image_reference.offer
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }

  os_disk {
    caching                = each.value.os_disk.caching
    storage_account_type   = each.value.os_disk.storage_account_type
    disk_size_gb           = each.value.os_disk.disk_size_gb
    disk_encryption_set_id = each.value.os_disk.disk_encryption_set_id
  }

  network_interface {
    name                          = each.value.network_interface.name
    primary                       = each.value.network_interface.primary
    enable_accelerated_networking = each.value.network_interface.enable_accelerated_networking

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = each.value.network_interface.subnet_id
    }
  }

  boot_diagnostics {
    storage_account_uri = each.value.boot_diagnostics.storage_account_uri
  }

  identity {
    type         = each.value.identity.type
    identity_ids = each.value.identity.type == "UserAssigned" || each.value.identity.type == "SystemAssigned, UserAssigned" ? each.value.identity.identity_ids : []
  }

  secure_boot_enabled        = each.value.secure_boot_enabled
  vtpm_enabled               = each.value.vtpm_enabled
  encryption_at_host_enabled = each.value.encryption_at_host_enabled
  zone_balance               = each.value.zone_balance
  upgrade_mode               = each.value.upgrade_mode
  health_probe_id            = each.value.health_probe_id

  dynamic "rolling_upgrade_policy" {
    for_each = each.value.upgrade_mode == "Rolling" ? [each.value.rolling_upgrade_policy] : []
    content {
      max_batch_instance_percent              = rolling_upgrade_policy.value.max_batch_instance_percent
      max_unhealthy_instance_percent          = rolling_upgrade_policy.value.max_unhealthy_instance_percent
      max_unhealthy_upgraded_instance_percent = rolling_upgrade_policy.value.max_unhealthy_upgraded_instance_percent
      pause_time_between_batches              = rolling_upgrade_policy.value.pause_time_between_batches
    }
  }

  dynamic "automatic_instance_repair" {
    for_each = each.value.automatic_instance_repair != null ? [each.value.automatic_instance_repair] : []
    content {
      enabled      = automatic_instance_repair.value.enabled
      grace_period = automatic_instance_repair.value.grace_period
    }
  }

  dynamic "automatic_os_upgrade_policy" {
    for_each = each.value.automatic_os_upgrade_policy != null ? [each.value.automatic_os_upgrade_policy] : []
    content {
      disable_automatic_rollback  = automatic_os_upgrade_policy.value.disable_automatic_rollback
      enable_automatic_os_upgrade = automatic_os_upgrade_policy.value.enable_automatic_os_upgrade
    }
  }

  dynamic "data_disk" {
    for_each = each.value.data_disks
    content {
      storage_account_type   = data_disk.value.storage_account_type
      disk_size_gb           = data_disk.value.disk_size_gb
      caching                = data_disk.value.caching
      lun                    = data_disk.value.lun
      create_option          = data_disk.value.create_option
      disk_encryption_set_id = data_disk.value.disk_encryption_set_id
    }
  }

  tags = merge(local.tags, each.value.tags)
}
