locals {
  # Look up the region abbreviation, fall back to the full region name
  region_short = lookup(var.region_abbreviations, var.region, var.region)

  # Build the base name with separator: workload-env-region[-suffix]
  name_parts = compact([
    var.workload,
    var.environment,
    local.region_short,
    var.suffix,
  ])

  base_name = join(var.separator, local.name_parts)

  # Base name without separators (for storage accounts, container registries, etc.)
  base_name_nosep = replace(local.base_name, var.separator, "")

  # Truncated variants for resources with length limits
  storage_account_name    = substr("st${local.base_name_nosep}", 0, min(24, length("st${local.base_name_nosep}")))
  container_registry_name = substr("cr${local.base_name_nosep}", 0, min(50, length("cr${local.base_name_nosep}")))
  key_vault_name          = substr("kv${var.separator}${local.base_name}", 0, min(24, length("kv${var.separator}${local.base_name}")))

  # Map of all generated names by resource type
  all_names = {
    resource_group         = "rg${var.separator}${local.base_name}"
    virtual_network        = "vnet${var.separator}${local.base_name}"
    subnet                 = "snet${var.separator}${local.base_name}"
    network_security_group = "nsg${var.separator}${local.base_name}"
    route_table            = "rt${var.separator}${local.base_name}"
    public_ip              = "pip${var.separator}${local.base_name}"
    nat_gateway            = "ng${var.separator}${local.base_name}"
    firewall               = "fw${var.separator}${local.base_name}"
    firewall_policy        = "fwp${var.separator}${local.base_name}"
    application_gateway    = "agw${var.separator}${local.base_name}"
    load_balancer          = "lb${var.separator}${local.base_name}"
    private_endpoint       = "pe${var.separator}${local.base_name}"
    front_door             = "fd${var.separator}${local.base_name}"
    vpn_gateway            = "vpng${var.separator}${local.base_name}"
    express_route          = "erc${var.separator}${local.base_name}"
    virtual_machine        = "vm${var.separator}${local.base_name}"
    vmss                   = "vmss${var.separator}${local.base_name}"
    aks_cluster            = "aks${var.separator}${local.base_name}"
    container_instance     = "ci${var.separator}${local.base_name}"
    container_registry     = local.container_registry_name
    storage_account        = local.storage_account_name
    key_vault              = local.key_vault_name
    app_service_plan       = "asp${var.separator}${local.base_name}"
    app_service            = "app${var.separator}${local.base_name}"
    dns_zone               = local.base_name
    log_analytics          = "log${var.separator}${local.base_name}"
  }
}
