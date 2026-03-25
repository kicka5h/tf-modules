locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_container_group" "this" {
  for_each = var.container_groups

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = each.value.os_type
  restart_policy      = each.value.restart_policy
  ip_address_type     = each.value.ip_address_type
  subnet_ids          = each.value.ip_address_type == "Private" ? each.value.subnet_ids : null
  dns_name_label      = each.value.ip_address_type == "Public" ? each.value.dns_name_label : null
  tags                = merge(local.tags, each.value.tags)

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.type == "SystemAssigned" ? null : identity.value.identity_ids
    }
  }

  dynamic "container" {
    for_each = each.value.containers
    content {
      name   = container.value.name
      image  = container.value.image
      cpu    = container.value.cpu
      memory = container.value.memory

      environment_variables        = container.value.environment_variables
      secure_environment_variables = container.value.secure_environment_variables
      commands                     = length(container.value.commands) > 0 ? container.value.commands : null

      dynamic "ports" {
        for_each = container.value.ports
        content {
          port     = ports.value.port
          protocol = ports.value.protocol
        }
      }

      dynamic "volume" {
        for_each = container.value.volume
        content {
          name                 = volume.value.name
          mount_path           = volume.value.mount_path
          read_only            = volume.value.read_only
          storage_account_name = volume.value.storage_account_name
          storage_account_key  = volume.value.storage_account_key
          share_name           = volume.value.share_name
        }
      }
    }
  }

  dynamic "image_registry_credential" {
    for_each = each.value.image_registry_credential
    content {
      server                    = image_registry_credential.value.server
      username                  = image_registry_credential.value.username
      password                  = image_registry_credential.value.password
      user_assigned_identity_id = image_registry_credential.value.user_assigned_identity_id
    }
  }

  dynamic "dns_config" {
    for_each = each.value.dns_config != null ? [each.value.dns_config] : []
    content {
      nameservers = dns_config.value.nameservers
    }
  }
}
