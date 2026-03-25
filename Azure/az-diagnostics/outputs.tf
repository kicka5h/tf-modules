output "diagnostic_settings" {
  description = "Map of diagnostic settings created, keyed by the logical name"
  value = {
    for k, v in azurerm_monitor_diagnostic_setting.this : k => {
      id   = v.id
      name = v.name
    }
  }
}
